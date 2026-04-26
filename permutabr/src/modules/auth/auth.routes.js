// /src/modules/auth/auth.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const passport = require('passport');
const rateLimit = require('express-rate-limit');
const authValidation = require('./auth.validation');
const authController = require('./auth.controller');
const logger = require('../../core/utils/logger');

const router = express.Router();

// ✅ FUNÇÃO AUXILIAR: Valida se uma origem é segura (não é domínio OAuth)
function isSafeOrigin(origin) {
    if (!origin) return false;
    try {
        const oauthDomains = [
            'login.microsoftonline.com',
            'accounts.google.com',
            'oauth.google.com',
            'login.live.com'
        ];
        const originHost = new URL(origin).hostname;
        return !oauthDomains.some(domain => originHost.includes(domain));
    } catch (error) {
        // Se não conseguir fazer parse da URL, considera inseguro
        return false;
    }
}

// ✅ FUNÇÃO AUXILIAR: Obtém frontendUrl seguro (prioriza sessão, depois valida origin)
function getSafeFrontendUrl(req, defaultUrl) {
    const frontendUrl = defaultUrl || process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';
    
    // Prioridade 1: Sessão (sempre seguro, foi salvo antes do OAuth)
    if (req.session?.oauthOrigin) {
        return req.session.oauthOrigin;
    }
    
    // Prioridade 2: Header Origin (mas só se for seguro)
    if (req.headers.origin && isSafeOrigin(req.headers.origin)) {
        return req.headers.origin;
    }
    
    // Fallback: URL padrão
    return frontendUrl;
}

// ✅ SEGURANÇA: Rate limit para login (mais restritivo)
const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutos
    max: 5, // 5 tentativas
    message: 'Muitas tentativas de login. Tente novamente em 15 minutos.',
    standardHeaders: true,
    legacyHeaders: false,
    skipSuccessfulRequests: true, // Não conta requisições bem-sucedidas
});

// --- ROTAS TRADICIONAIS (sem OAuth) ---

router.post('/registrar', celebrate(authValidation.registrar), authController.registrar);
router.post('/confirmar-email', celebrate(authValidation.confirmarEmail), authController.confirmarEmail);
router.post('/login', loginLimiter, celebrate(authValidation.login), authController.login);
router.post('/solicitar-recuperacao', celebrate(authValidation.solicitarRecuperacao), authController.solicitarRecuperacao);
router.post('/validar-codigo', celebrate(authValidation.validarCodigo), authController.validarCodigo);
router.post('/redefinir-senha', celebrate(authValidation.redefinirSenha), authController.redefinirSenha);

// --- GOOGLE OAUTH ---

router.get('/google', (req, res, next) => {
    logger.debug('Iniciando fluxo Google OAuth', {
        platform: req.query.platform || 'web',
        origin: req.query.origin || req.headers.origin || 'não fornecido',
        sessionId: req.sessionID || 'não presente'
    });
    
    // ✅ CORREÇÃO: Salva a origem do frontend na sessão para usar no callback
    if (req.query.origin) {
        req.session = req.session || {};
        req.session.oauthOrigin = req.query.origin;
        logger.debug('Origem salva na sessão (query) - Google OAuth', { oauthOrigin: req.session.oauthOrigin });
    } else if (req.headers.origin) {
        // Fallback: usa o header Origin se não foi passado como query param
        req.session = req.session || {};
        req.session.oauthOrigin = req.headers.origin;
        logger.debug('Origem salva da header Origin - Google OAuth', { oauthOrigin: req.session.oauthOrigin });
    }
    
    // Salva platform na sessão também
    if (req.query.platform) {
        req.session = req.session || {};
        req.session.oauthPlatform = req.query.platform;
    }
    
    // ✅ CRÍTICO: Salva a sessão antes do redirecionamento OAuth
    req.session.save((err) => {
        if (err) {
            logger.error('Erro ao salvar sessão antes do OAuth Google', { error: err.message });
            return next(err);
        }
        logger.debug('Sessão salva com sucesso antes do OAuth Google', {
            sessionId: req.sessionID,
            oauthOrigin: req.session.oauthOrigin,
            oauthPlatform: req.session.oauthPlatform
        });
        
        passport.authenticate('google', {
            scope: ['profile', 'email'],
            session: false
        })(req, res, next);
    });
});

router.get('/google/callback',
    (req, res, next) => {
        // ✅ CORREÇÃO: Usa origem dinâmica para failureRedirect também
        const frontendUrl = getSafeFrontendUrl(req);
        
        passport.authenticate('google', {
            failureRedirect: `${frontendUrl}?error=oauth_failed`,
            session: false
        })(req, res, next);
    },
    authController.googleCallback
);

// --- MICROSOFT OAUTH ---

// Rota de início do fluxo OAuth
router.get('/microsoft', (req, res, next) => {
    logger.debug('Iniciando fluxo Microsoft OAuth', {
        platform: req.query.platform || 'web',
        origin: req.query.origin || req.headers.origin || 'não fornecido',
        sessionId: req.sessionID || 'não presente',
        callbackUrl: process.env.MICROSOFT_CALLBACK_URL || `${process.env.BASE_URL || 'https://br.permutapolicial.com.br'}/api/auth/microsoft/callback`
    });
    
    // ✅ CORREÇÃO: Salva a origem do frontend na sessão para usar no callback
    if (req.query.origin) {
        req.session = req.session || {};
        req.session.oauthOrigin = req.query.origin;
        logger.debug('Origem salva na sessão (query) - Microsoft OAuth', { oauthOrigin: req.session.oauthOrigin });
    } else if (req.headers.origin) {
        // Fallback: usa o header Origin se não foi passado como query param
        req.session = req.session || {};
        req.session.oauthOrigin = req.headers.origin;
        logger.debug('Origem salva da header Origin - Microsoft OAuth', { oauthOrigin: req.session.oauthOrigin });
    }
    
    // Salva platform na sessão também
    if (req.query.platform) {
        req.session = req.session || {};
        req.session.oauthPlatform = req.query.platform;
    }
    
    // ✅ CRÍTICO: Salva a sessão antes do redirecionamento OAuth
    req.session.save((err) => {
        if (err) {
            logger.error('Erro ao salvar sessão antes do OAuth Microsoft', { error: err.message });
            return next(err);
        }
        logger.debug('Sessão salva com sucesso antes do OAuth Microsoft', {
            sessionId: req.sessionID,
            oauthOrigin: req.session.oauthOrigin,
            oauthPlatform: req.session.oauthPlatform,
            // ✅ DEBUG: Informações adicionais sobre a sessão
            cookieName: 'permuta.dev.sid',
            cookieWillBeSet: true
        });
        
        // ✅ CORREÇÃO: prompt: 'select_account' já está configurado na estratégia
        // A estratégia já inclui customParams com prompt: 'select_account'
        // ✅ IMPORTANTE: session: false significa que não serializa o usuário na sessão,
        // mas a sessão ainda é usada para armazenar o state do OAuth
        passport.authenticate('microsoft', {
            session: false
        })(req, res, next);
    });
});

// ✅ CORREÇÃO CRÍTICA: Microsoft retorna via POST, não GET!
// Com form_post, o Microsoft envia dados via POST e espera uma resposta adequada
router.post('/microsoft/callback', (req, res, next) => {
    logger.debug('CALLBACK MICROSOFT RECEBIDO (POST)', {
        body: req.body,
        query: req.query,
        origin: req.headers.origin || 'não fornecido',
        referer: req.headers.referer || 'não fornecido',
        sessionId: req.sessionID || 'não presente',
        oauthOrigin: req.session?.oauthOrigin || 'não salvo',
        oauthPlatform: req.session?.oauthPlatform || 'não salvo',
        cookies: req.headers.cookie || 'nenhum cookie',
        // ✅ DEBUG: Verifica se a sessão está presente
        sessionPresent: !!req.session,
        sessionKeys: req.session ? Object.keys(req.session) : []
    });

    // ✅ CORREÇÃO: Verifica se há erro no body (Microsoft pode enviar erros via POST)
    if (req.body?.error) {
        logger.error('ERRO recebido do Microsoft no callback', {
            error: req.body.error,
            description: req.body.error_description || 'não fornecida'
        });
        
        const detectPlatform = (req) => {
            const platformParam = req.query?.platform || req.body?.platform || req.session?.oauthPlatform;
            if (platformParam === 'mobile') return 'mobile';
            if (platformParam === 'pwa') return 'pwa';
            const userAgent = req.headers['user-agent'] || '';
            const isPWA = userAgent.includes('wv') || req.headers['x-pwa'] === 'true' || req.headers['sec-fetch-site'] === 'none';
            return isPWA && !platformParam ? 'pwa' : 'web';
        };
        const platform = detectPlatform(req);
        let frontendUrlError = process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';
        if (platform !== 'mobile') {
            frontendUrlError = getSafeFrontendUrl(req, frontendUrlError);
        }
        
        const errorUrl = platform === 'mobile'
            ? `permutapolicial://auth/callback?error=microsoft_oauth_error&message=${encodeURIComponent(req.body.error_description || req.body.error)}`
            : `${frontendUrlError}?error=microsoft_oauth_error&message=${encodeURIComponent(req.body.error_description || req.body.error)}`;
        return res.redirect(302, errorUrl);
    }

    // ✅ CORREÇÃO: Usa função auxiliar para detectar plataforma
    // Importa a função do controller (ou cria uma versão compartilhada)
    const detectPlatform = (req) => {
        const platformParam = req.query?.platform || req.body?.platform || req.session?.oauthPlatform;
        if (platformParam === 'mobile') return 'mobile';
        if (platformParam === 'pwa') return 'pwa';
        const userAgent = req.headers['user-agent'] || '';
        const isPWA = userAgent.includes('wv') || req.headers['x-pwa'] === 'true' || req.headers['sec-fetch-site'] === 'none';
        return isPWA && !platformParam ? 'pwa' : 'web';
    };
    
    const platform = detectPlatform(req);
    logger.debug('Platform detectado no callback Microsoft', {
        platform,
        description: platform === 'mobile' ? 'Mobile (APK)' : platform === 'pwa' ? 'PWA (Instalado)' : 'Web (Navegador)'
    });
    
    // ✅ CORREÇÃO: Usa origem dinâmica para failureRedirect também
    let frontendUrl = process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';
    if (platform !== 'mobile') {
        frontendUrl = getSafeFrontendUrl(req, frontendUrl);
    }
    
    logger.debug('Iniciando autenticação passport-azure-ad', { frontendUrl });
    
    // ✅ CRÍTICO: Garante que sempre há uma resposta, mesmo em caso de erro
    try {
        passport.authenticate('microsoft', {
            session: false,
            failureRedirect: platform === 'mobile'
                ? 'permutapolicial://auth/callback?error=microsoft_oauth_failed'
                : `${frontendUrl}?error=microsoft_oauth_failed`
        }, (err, user, info) => {
            logger.debug('Resultado da autenticação Microsoft', {
                hasError: !!err,
                errorMessage: err ? err.message : null,
                hasUser: !!user,
                info: info || null
            });

            // ✅ CORREÇÃO: Usa origem dinâmica para erros também
            let frontendUrlError = process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';
            if (platform !== 'mobile') {
                frontendUrlError = getSafeFrontendUrl(req, frontendUrlError);
            }
            
            if (err) {
                logger.error('ERRO na autenticação Microsoft', {
                    message: err.message,
                    stack: err.stack
                });
                const errorUrl = platform === 'mobile'
                    ? `permutapolicial://auth/callback?error=microsoft_auth_error&message=${encodeURIComponent(err.message || 'Erro desconhecido')}`
                    : `${frontendUrlError}?error=microsoft_auth_error&message=${encodeURIComponent(err.message || 'Erro desconhecido')}`;
                return res.redirect(302, errorUrl);
            }

            if (!user) {
                logger.error('Usuário não autenticado (Microsoft)', { 
                    info,
                    // ✅ DEBUG: Informações adicionais para diagnóstico
                    hasError: !!err,
                    errorMessage: err ? err.message : null,
                    body: req.body,
                    sessionId: req.sessionID
                });
                
                // ✅ CORREÇÃO: Redireciona com mensagem mais descritiva
                const errorMessage = info?.message || 'Falha na autenticação. Tente novamente.';
                const errorUrl = platform === 'mobile'
                    ? `permutapolicial://auth/callback?error=microsoft_no_user&message=${encodeURIComponent(errorMessage)}`
                    : `${frontendUrlError}?error=microsoft_no_user&message=${encodeURIComponent(errorMessage)}`;
                return res.redirect(302, errorUrl);
            }

            // ✅ Usuário autenticado com sucesso - passa platform para o callback handler
            logger.debug('Usuário autenticado com sucesso! Redirecionando para callback handler');
            req.user = user;
            req.query.platform = platform === 'mobile' ? 'mobile' : platform === 'pwa' ? 'pwa' : undefined;
            
            // ✅ CRÍTICO: Garante que o callback handler sempre responde
            try {
                authController.googleCallback(req, res, next);
            } catch (callbackError) {
                logger.error('ERRO no callback handler', { error: callbackError.message });
                const errorUrl = platform === 'mobile'
                    ? `permutapolicial://auth/callback?error=callback_error&message=${encodeURIComponent(callbackError.message || 'Erro ao processar callback')}`
                    : `${frontendUrlError}?error=callback_error&message=${encodeURIComponent(callbackError.message || 'Erro ao processar callback')}`;
                return res.redirect(302, errorUrl);
            }

        })(req, res, next);
    } catch (authError) {
        logger.error('ERRO ao processar autenticação Microsoft', { error: authError.message });
        const detectPlatform = (req) => {
            const platformParam = req.query?.platform || req.body?.platform || req.session?.oauthPlatform;
            if (platformParam === 'mobile') return 'mobile';
            if (platformParam === 'pwa') return 'pwa';
            const userAgent = req.headers['user-agent'] || '';
            const isPWA = userAgent.includes('wv') || req.headers['x-pwa'] === 'true' || req.headers['sec-fetch-site'] === 'none';
            return isPWA && !platformParam ? 'pwa' : 'web';
        };
        const platform = detectPlatform(req);
        let frontendUrlError = process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';
        if (platform !== 'mobile') {
            frontendUrlError = getSafeFrontendUrl(req, frontendUrlError);
        }
        const errorUrl = platform === 'mobile'
            ? `permutapolicial://auth/callback?error=auth_process_error&message=${encodeURIComponent(authError.message || 'Erro ao processar autenticação')}`
            : `${frontendUrlError}?error=auth_process_error&message=${encodeURIComponent(authError.message || 'Erro ao processar autenticação')}`;
        return res.redirect(302, errorUrl);
    }
});

// ✅ FALLBACK: Rota GET para casos onde o Microsoft redireciona incorretamente
// (alguns casos edge podem fazer o Microsoft usar GET ao invés de POST)
router.get('/microsoft/callback', (req, res, next) => {
    logger.warn('CALLBACK MICROSOFT RECEBIDO VIA GET (não esperado, mas tratando...)', {
        query: req.query,
        origin: req.headers.origin || 'não fornecido'
    });
    
    // Se há erro na query, redireciona com erro
    if (req.query.error) {
        logger.error('ERRO recebido do Microsoft (GET)', { error: req.query.error });
        const detectPlatform = (req) => {
            const platformParam = req.query?.platform || req.body?.platform || req.session?.oauthPlatform;
            if (platformParam === 'mobile') return 'mobile';
            if (platformParam === 'pwa') return 'pwa';
            const userAgent = req.headers['user-agent'] || '';
            const isPWA = userAgent.includes('wv') || req.headers['x-pwa'] === 'true' || req.headers['sec-fetch-site'] === 'none';
            return isPWA && !platformParam ? 'pwa' : 'web';
        };
        const platform = detectPlatform(req);
        let frontendUrl = process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';
        if (platform !== 'mobile') {
            frontendUrl = getSafeFrontendUrl(req, frontendUrl);
        }
        const errorUrl = platform === 'mobile'
            ? `permutapolicial://auth/callback?error=microsoft_oauth_error&message=${encodeURIComponent(req.query.error_description || req.query.error)}`
            : `${frontendUrl}?error=microsoft_oauth_error&message=${encodeURIComponent(req.query.error_description || req.query.error)}`;
        return res.redirect(errorUrl);
    }
    
    // Se há código na query, tenta processar (mas isso não deveria acontecer com form_post)
    if (req.query.code || req.query.id_token) {
        logger.debug('Código encontrado na query (GET) - tentando processar');
        // Reenvia como POST para o handler correto
        return res.redirect(302, `/api/auth/microsoft/callback?code=${req.query.code}&state=${req.query.state || ''}`);
    }
    
    // Se não há código nem erro, pode ser um redirecionamento incorreto
    const detectPlatform = (req) => {
        const platformParam = req.query?.platform || req.body?.platform || req.session?.oauthPlatform;
        if (platformParam === 'mobile') return 'mobile';
        if (platformParam === 'pwa') return 'pwa';
        const userAgent = req.headers['user-agent'] || '';
        const isPWA = userAgent.includes('wv') || req.headers['x-pwa'] === 'true' || req.headers['sec-fetch-site'] === 'none';
        return isPWA && !platformParam ? 'pwa' : 'web';
    };
    const platform = detectPlatform(req);
    let frontendUrl = process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';
    if (platform !== 'mobile') {
        frontendUrl = getSafeFrontendUrl(req, frontendUrl);
    }
    
    logger.error('Callback GET sem código ou erro - redirecionando para frontend com erro');
    const errorUrl = platform === 'mobile'
        ? 'permutapolicial://auth/callback?error=microsoft_callback_invalid'
        : `${frontendUrl}?error=microsoft_callback_invalid`;
    return res.redirect(errorUrl);
});

module.exports = router;