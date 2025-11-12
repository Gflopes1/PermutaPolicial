// /src/modules/auth/auth.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const passport = require('passport');
const authValidation = require('./auth.validation');
const authController = require('./auth.controller');

const router = express.Router();

// --- ROTAS TRADICIONAIS (sem OAuth) ---

router.post('/registrar', celebrate(authValidation.registrar), authController.registrar);
router.post('/confirmar-email', celebrate(authValidation.confirmarEmail), authController.confirmarEmail);
router.post('/login', celebrate(authValidation.login), authController.login);
router.post('/solicitar-recuperacao', celebrate(authValidation.solicitarRecuperacao), authController.solicitarRecuperacao);
router.post('/validar-codigo', celebrate(authValidation.validarCodigo), authController.validarCodigo);
router.post('/redefinir-senha', celebrate(authValidation.redefinirSenha), authController.redefinirSenha);

// --- GOOGLE OAUTH ---

router.get('/google',
    passport.authenticate('google', {
        scope: ['profile', 'email'],
        session: false
    })
);

router.get('/google/callback',
    passport.authenticate('google', {
        failureRedirect: `${process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br'}?error=oauth_failed`,
        session: false
    }),
    authController.googleCallback
);

// --- MICROSOFT OAUTH ---

// Rota de início do fluxo OAuth
router.get('/microsoft', (req, res, next) => {
    console.log('🔵 Iniciando fluxo Microsoft OAuth...');
    passport.authenticate('microsoft', {
        session: false,
        // ✅ CORREÇÃO: Força o prompt de seleção de conta
        prompt: 'select_account'
    })(req, res, next);
});

// ✅ CORREÇÃO CRÍTICA: Microsoft retorna via POST, não GET!
router.post('/microsoft/callback', (req, res, next) => {
    console.log('═══════════════════════════════════════');
    console.log('🔵 CALLBACK MICROSOFT RECEBIDO (POST)');
    console.log('📍 Body:', req.body);
    console.log('📍 Query:', req.query);
    console.log('═══════════════════════════════════════');

    passport.authenticate('microsoft', {
        session: false,
        failureRedirect: `${process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br'}?error=microsoft_oauth_failed`
    }, (err, user, info) => {
        console.log('🔍 Resultado da autenticação Microsoft:');
        console.log('   Erro:', err);
        console.log('   User:', user ? '✅ Presente' : '❌ Ausente');
        console.log('   Info:', info);

        if (err) {
            console.error('💥 ERRO na autenticação Microsoft:', err);
            return res.redirect(`${process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br'}?error=microsoft_auth_error&message=${encodeURIComponent(err.message)}`);
        }

        if (!user) {
            console.error('❌ Usuário não autenticado (Microsoft)');
            return res.redirect(`${process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br'}?error=microsoft_no_user`);
        }

        // ✅ Usuário autenticado com sucesso
        req.user = user;
        authController.googleCallback(req, res, next);

    })(req, res, next);
});

module.exports = router;