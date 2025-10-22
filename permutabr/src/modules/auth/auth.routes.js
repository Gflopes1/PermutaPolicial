// /src/modules/auth/auth.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const passport = require('passport');
const authValidation = require('./auth.validation');
const authController = require('./auth.controller');

const router = express.Router();

// --- ROTAS EXISTENTES (sem autenticação) ---

// Rota de Registro
router.post(
    '/registrar',
    celebrate(authValidation.registrar),
    authController.registrar
);

// Rota de Confirmação de Email
router.post(
    '/confirmar-email',
    celebrate(authValidation.confirmarEmail),
    authController.confirmarEmail
);

// Rota de Login
router.post(
    '/login',
    celebrate(authValidation.login),
    authController.login
);

// Rotas de Recuperação de Senha
router.post(
    '/solicitar-recuperacao',
    celebrate(authValidation.solicitarRecuperacao),
    authController.solicitarRecuperacao
);

router.post(
    '/validar-codigo',
    celebrate(authValidation.validarCodigo),
    authController.validarCodigo
);

router.post(
    '/redefinir-senha',
    celebrate(authValidation.redefinirSenha),
    authController.redefinirSenha
);

router.get('/google',
    passport.authenticate('google', {
        scope: ['profile', 'email'],
        session: false
    })
);

router.get(
    '/google/callback',
    passport.authenticate('google', {
        failureRedirect: `${process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br'}?error=oauth_failed`,
        session: false
    }),
    authController.googleCallback
);

router.get('/microsoft',
    passport.authenticate('microsoft', {
        session: false
    })
);

router.post('/microsoft/callback',
    passport.authenticate('microsoft', {
        failureRedirect: `${process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br'}?error=oauth_failed`,
    }),
    authController.googleCallback // REUTILIZAMOS o mesmo controller!
);

module.exports = router;