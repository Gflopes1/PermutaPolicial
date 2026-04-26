// /src/modules/assistant/assistant.routes.js

const express = require('express');
const assistantController = require('./assistant.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const premiumMiddleware = require('../../core/middlewares/premium.middleware');
const usageLimitMiddleware = require('../../core/middlewares/usageLimit.middleware');

const router = express.Router();

// Todas as rotas requerem autenticação
router.use(authMiddleware);
// Todas as rotas precisam verificar se o usuário é Premium
router.use(premiumMiddleware);

// POST /api/assistant/consultar
// Limite Free: 3 consultas/dia. Premium: Ilimitado
router.post('/consultar', usageLimitMiddleware('ai_consult', 3), assistantController.consultar);

// POST /api/assistant/gerar-boletim
// Exclusivo para Premium (middleware premiumMiddleware já verifica)
router.post('/gerar-boletim', premiumMiddleware.requirePremium, assistantController.gerarBoletim);

module.exports = router;

