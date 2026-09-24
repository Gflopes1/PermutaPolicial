// /src/modules/auth/auth.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const passport = require('passport');
const rateLimit = require('express-rate-limit');
const authValidation = require('./auth.validation');
const authController = require('./auth.controller');
const logger = require('../../core/utils/logger');
const {
    resolveSafeFrontendOrigin,
    saveOAuthOriginToSession,
    isAllowedFrontendOrigin,
} = require('../../core/utils/frontend-url.utils');

const router = express.Router();

function getSafeFrontendUrl(req, defaultUrl) {
    const fallback = defaultUrl || process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br';
    return resolveSafeFrontendOrigin(req.session?.oauthOrigin, fallback);
}

function trySaveOAuthOrigin(req) {
    if (req.query.origin && saveOAuthOriginToSession(req, req.query.origin)) {
        logger.debug('Origem OAuth salva (query)', { oauthOrigin: req.session.oauthOrigin });
        return;
    }
    if (req.headers.origin && isAllowedFrontendOrigin(req.headers.origin)) {
        saveOAuthOriginToSession(req, req.headers.origin);
        logger.debug('Origem OAuth salva (header)', { oauthOrigin: req.session.oauthOrigin });
    }
}

function saveOAuthSessionAndAuthenticate(req, res, next, provider, options = {}) {
    trySaveOAuthOrigin(req);
    req.session = req.session || {};
    if (req.query.platform) {
        req.session.oauthPlatform = req.query.platform;
    }
    if (req.query.id_funcional) {
        req.session.oauthIdFuncional = String(req.query.id_funcional).trim().slice(0, 64);
    }
    if (req.query.edital_id) {
        const editalId = parseInt(req.query.edital_id, 10);
        if (Number.isFinite(editalId) && editalId > 0) {
            req.session.oauthEditalId = editalId;
        }
    }
    if (req.query.return_to) {
        const returnTo = String(req.query.return_to);
        // Apenas caminhos internos relativos seguros
        if (returnTo.startsWith('/') && !returnTo.startsWith('//')) {
            req.session.oauthReturnTo = returnTo.slice(0, 300);
        }
    }
    if (req.query.ref) {
        const ref = String(req.query.ref).trim().slice(0, 12);
        if (ref.length >= 3) {
            req.session.oauthReferralCode = ref.toUpperCase();
        }
    }

    req.session.save((err) => {
        if (err) {
            logger.error(`Erro ao salvar sessão antes do OAuth ${provider}`, { error: err.message });
            return next(err);
        }
        passport.authenticate(provider, options)(req, res, next);
    });
}

const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 5,
    message: 'Muitas tentativas de login. Tente novamente em 15 minutos.',
    standardHeaders: true,
    legacyHeaders: false,
    skipSuccessfulRequests: true,
});

router.post('/registrar', celebrate(authValidation.registrar), authController.registrar);
router.post('/confirmar-email', celebrate(authValidation.confirmarEmail), authController.confirmarEmail);
router.post('/login', loginLimiter, celebrate(authValidation.login), authController.login);
router.post('/solicitar-recuperacao', celebrate(authValidation.solicitarRecuperacao), authController.solicitarRecuperacao);
router.post('/validar-codigo', celebrate(authValidation.validarCodigo), authController.validarCodigo);
router.post('/redefinir-senha', celebrate(authValidation.redefinirSenha), authController.redefinirSenha);

router.get('/google', (req, res, next) => {
    saveOAuthSessionAndAuthenticate(req, res, next, 'google', {
        scope: ['profile', 'email'],
        session: false,
    });
});

router.post(
    '/google/native',
    loginLimiter,
    celebrate(authValidation.googleNative),
    authController.googleNative
);

router.post(
    '/exchange-code',
    celebrate(authValidation.exchangeCode),
    authController.exchangeCode
);

router.get('/google/callback', (req, res, next) => {
    const frontendUrl = getSafeFrontendUrl(req);
    passport.authenticate('google', {
        failureRedirect: `${frontendUrl}/auth?error=oauth_failed`,
        session: false,
    })(req, res, next);
}, authController.googleCallback);

router.get('/microsoft', (req, res, next) => {
    saveOAuthSessionAndAuthenticate(req, res, next, 'microsoft', { session: false });
});

router.post('/microsoft/callback', authController.microsoftCallbackPost);
router.get('/microsoft/callback', authController.microsoftCallbackGet);

module.exports = router;
