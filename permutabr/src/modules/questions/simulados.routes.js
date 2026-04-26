const express = require('express');
const { celebrate } = require('celebrate');
const simuladosController = require('./simulados.controller');
const simuladosValidation = require('./simulados.validation');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const premiumMiddleware = require('../../core/middlewares/premium.middleware');
const usageLimitMiddleware = require('../../core/middlewares/usageLimit.middleware');

const router = express.Router();

// Todas as rotas requerem autenticação
router.use(authMiddleware);
// Todas as rotas precisam verificar se o usuário é Premium (para definir limites)
router.use(premiumMiddleware);

router.get(
  '/create-options',
  simuladosController.getCreateOptions
);

router.post(
  '/',
  celebrate(simuladosValidation.createSimulado),
  // Middleware de limite aplicado internamente no service (checkUserLimits)
  // Free: 10 questões/dia, Premium: 120 questões/dia
  simuladosController.createSimulado
);

router.post(
  '/:id/start',
  celebrate(simuladosValidation.startSimulado),
  simuladosController.startSimulado
);

router.get(
  '/:id/question',
  celebrate(simuladosValidation.getCurrentQuestion),
  simuladosController.getCurrentQuestion
);

router.post(
  '/:id/answer',
  celebrate(simuladosValidation.submitAnswer),
  simuladosController.submitAnswer
);

router.get(
  '/:id/result',
  celebrate(simuladosValidation.getResult),
  simuladosController.getResult
);

module.exports = router;


