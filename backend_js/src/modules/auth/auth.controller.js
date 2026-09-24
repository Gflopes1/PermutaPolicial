// /src/modules/auth/auth.controller.js

const authService = require('./auth.service');
const logger = require('../../core/utils/logger');
const passport = require('passport');
const { createCode } = require('../../core/services/oauth-code.store');
const {
    detectPlatform,
    getOAuthFrontendUrl,
    buildOAuthErrorUrl,
} = require('./auth.utils');

function buildOAuthRedirectUrl({ platform, frontendUrl, code, completar, nextPath }) {
    const params = new URLSearchParams({ code });
    if (completar) params.set('completar', 'true');
    if (nextPath) params.set('next', nextPath);

    if (platform === 'mobile') {
        return `permutapolicial://auth/callback?${params.toString()}`;
    }
    return `${frontendUrl}/auth/callback?${params.toString()}`;
}

const handleRequest = (servicePromise, successStatus) => async (req, res, next) => {
    try {
        const result = await servicePromise(req);
        res.status(successStatus).json({
            status: 'success',
            data: result,
        });
    } catch (error) {
        next(error);
    }
};

async function oauthCallbackHandler(req, res) {
    logger.info('OAuth callback handler: iniciando redirect para frontend', {
        url: req.url,
        hasUser: !!req.user,
        userId: req.user?.id,
        sessionId: req.sessionID || 'não presente',
        oauthOrigin: req.session?.oauthOrigin || null,
    });

    if (!req.user) {
        const platform = detectPlatform(req);
        if (platform === 'mobile') {
            return res.redirect(302, 'permutapolicial://auth/callback?error=oauth_failed');
        }
        const frontendUrl = getOAuthFrontendUrl(req);
        return res.redirect(302, `${frontendUrl}/auth?error=oauth_failed`);
    }

    const oauthIdFuncional = req.session?.oauthIdFuncional || null;
    const oauthEditalId = req.session?.oauthEditalId || null;
    const oauthReturnTo = req.session?.oauthReturnTo || null;

    if (oauthIdFuncional || oauthEditalId) {
        try {
            const policiaisOAuthRepository = require('../policiais/policiais.oauth.repository');
            const updated = await policiaisOAuthRepository.applyEditalQuickSignupDefaults(req.user.id, {
                idFuncional: oauthIdFuncional,
                assignAluno: !!oauthEditalId,
            });
            if (updated) {
                req.user = updated;
            }
        } catch (e) {
            logger.error('Falha ao aplicar defaults de inscrição rápida no edital', {
                error: e.message,
                userId: req.user.id,
            });
        }
    }

    // Limpa dados sensíveis da sessão OAuth
    if (req.session) {
        delete req.session.oauthIdFuncional;
        delete req.session.oauthEditalId;
        delete req.session.oauthReturnTo;
    }

    const result = await authService.handleOAuthLogin(req.user);
    const perfilCompleto =
        req.user.forca_id != null &&
        (req.user.unidade_atual_id != null || req.user.municipio_atual_id != null);

    const editalQuickSignup =
        !!oauthEditalId &&
        !!req.user.id_funcional &&
        !!(req.user.agente_verificado && req.user.agente_verificado !== 0);

    const platform = detectPlatform(req);
    const frontendUrl = platform !== 'mobile' ? getOAuthFrontendUrl(req) : null;
    const safeReturnTo =
        oauthReturnTo && oauthReturnTo.startsWith('/') && !oauthReturnTo.startsWith('//')
            ? oauthReturnTo
            : oauthEditalId
                ? `/editais/${oauthEditalId}`
                : null;

    const oauthCode = createCode({
        token: result.token,
        completar: !perfilCompleto && !(editalQuickSignup && safeReturnTo),
        next: editalQuickSignup && safeReturnTo ? safeReturnTo : null,
    });

    const redirectUrl = buildOAuthRedirectUrl({
        platform,
        frontendUrl,
        code: oauthCode,
        completar: !perfilCompleto && !(editalQuickSignup && safeReturnTo),
        nextPath: editalQuickSignup && safeReturnTo ? safeReturnTo : null,
    });

    logger.info('OAuth callback: redirect emitido', {
        platform,
        frontendUrl,
        perfilCompleto,
        path: '/auth/callback',
    });

    try {
        res.redirect(302, redirectUrl);
    } catch (redirectError) {
        logger.error('Erro ao redirecionar após OAuth', { error: redirectError.message });
        res.status(200).send(`
            <!DOCTYPE html>
            <html>
            <head>
                <meta http-equiv="refresh" content="0;url=${redirectUrl}">
                <script>window.location.href = "${redirectUrl}";</script>
            </head>
            <body>
                <p>Redirecionando...</p>
                <a href="${redirectUrl}">Clique aqui se não for redirecionado automaticamente</a>
            </body>
            </html>
        `);
    }
}

const googleCallbackHandler = async (req, res, next) => {
    try {
        await oauthCallbackHandler(req, res);
    } catch (error) {
        logger.error('Erro no callback OAuth', { message: error.message });
        const platform = detectPlatform(req);
        if (platform === 'mobile') {
            return res.redirect(
                302,
                `permutapolicial://auth/callback?error=oauth_failed&message=${encodeURIComponent(error.message)}`
            );
        }
        const frontendUrl = getOAuthFrontendUrl(req);
        res.redirect(
            302,
            `${frontendUrl}/auth?error=oauth_failed&message=${encodeURIComponent(error.message)}`
        );
    }
};

const microsoftCallbackPost = (req, res, next) => {
    logger.debug('Callback Microsoft (POST)', {
        sessionId: req.sessionID || 'não presente',
        oauthOrigin: req.session?.oauthOrigin || 'não salvo',
    });

    if (req.body?.error) {
        logger.error('Erro recebido do Microsoft', {
            error: req.body.error,
            description: req.body.error_description,
        });
        const platform = detectPlatform(req);
        const errorUrl = buildOAuthErrorUrl(
            req,
            platform,
            'microsoft_oauth_error',
            req.body.error_description || req.body.error
        );
        return res.redirect(302, errorUrl);
    }

    const platform = detectPlatform(req);
    const frontendUrl = platform !== 'mobile' ? getOAuthFrontendUrl(req) : null;
    const failureRedirect =
        platform === 'mobile'
            ? 'permutapolicial://auth/callback?error=microsoft_oauth_failed'
            : `${frontendUrl}/auth?error=microsoft_oauth_failed`;

    try {
        passport.authenticate('microsoft', { session: false, failureRedirect }, (err, user, info) => {
            if (err) {
                logger.error('Erro na autenticação Microsoft', { message: err.message });
                const errorUrl = buildOAuthErrorUrl(req, platform, 'microsoft_auth_error', err.message);
                return res.redirect(302, errorUrl);
            }

            if (!user) {
                logger.error('Usuário não autenticado (Microsoft)', { info });
                const errorUrl = buildOAuthErrorUrl(
                    req,
                    platform,
                    'microsoft_no_user',
                    info?.message || 'Falha na autenticação. Tente novamente.'
                );
                return res.redirect(302, errorUrl);
            }

            req.user = user;
            req.query.platform =
                platform === 'mobile' ? 'mobile' : platform === 'pwa' ? 'pwa' : undefined;

            googleCallbackHandler(req, res, next).catch((callbackError) => {
                logger.error('Erro no callback handler Microsoft', { error: callbackError.message });
                const errorUrl = buildOAuthErrorUrl(req, platform, 'callback_error', callbackError.message);
                res.redirect(302, errorUrl);
            });
        })(req, res, next);
    } catch (authError) {
        logger.error('Erro ao processar autenticação Microsoft', { error: authError.message });
        const errorUrl = buildOAuthErrorUrl(req, detectPlatform(req), 'auth_process_error', authError.message);
        res.redirect(302, errorUrl);
    }
};

const microsoftCallbackGet = (req, res) => {
    logger.warn('Callback Microsoft via GET (fallback)', { query: req.query });
    const platform = detectPlatform(req);

    if (req.query.error) {
        const errorUrl = buildOAuthErrorUrl(
            req,
            platform,
            'microsoft_oauth_error',
            req.query.error_description || req.query.error
        );
        return res.redirect(302, errorUrl);
    }

    if (req.query.code || req.query.id_token) {
        return res.redirect(
            302,
            `/api/auth/microsoft/callback?code=${req.query.code}&state=${req.query.state || ''}`
        );
    }

    const errorUrl = buildOAuthErrorUrl(req, platform, 'microsoft_callback_invalid', 'Callback inválido');
    res.redirect(302, errorUrl);
};

module.exports = {
    registrar: handleRequest((req) => authService.registrar(req.body), 201),
    confirmarEmail: handleRequest((req) => authService.confirmarEmail(req.body), 200),
    login: handleRequest((req) => authService.login(req.body), 200),
    solicitarRecuperacao: handleRequest((req) => authService.solicitarRecuperacao(req.body), 200),
    validarCodigo: handleRequest((req) => authService.validarCodigo(req.body), 200),
    redefinirSenha: handleRequest((req) => authService.redefinirSenha(req.body), 200),
    exchangeCode: handleRequest((req) => authService.exchangeOAuthCode(req.body.code), 200),
    googleCallback: googleCallbackHandler,
    googleNative: handleRequest((req) => authService.loginWithGoogleIdToken(req.body), 200),
    microsoftCallbackPost,
    microsoftCallbackGet,
};
