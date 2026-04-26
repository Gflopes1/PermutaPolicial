// /src/modules/analytics/analytics.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const analyticsValidation = require('./analytics.validation');
const analyticsController = require('./analytics.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const adminMiddleware = require('../../core/middlewares/admin.middleware');

const router = express.Router();

// Rotas públicas (para tracking)
router.post(
  '/evento',
  celebrate(analyticsValidation.registrarEvento),
  analyticsController.registrarEvento
);

router.post(
  '/page-view',
  celebrate(analyticsValidation.registrarPageView),
  analyticsController.registrarPageView
);

router.post(
  '/tempo-permanencia',
  celebrate(analyticsValidation.atualizarTempoPermanencia),
  analyticsController.atualizarTempoPermanencia
);

router.post(
  '/sessao',
  celebrate(analyticsValidation.criarOuAtualizarSessao),
  analyticsController.criarOuAtualizarSessao
);

router.post(
  '/sessao/finalizar',
  celebrate(analyticsValidation.finalizarSessao),
  analyticsController.finalizarSessao
);

// Rotas protegidas (apenas admin)
router.get(
  '/estatisticas',
  authMiddleware,
  adminMiddleware,
  celebrate(analyticsValidation.getEstatisticasGerais),
  analyticsController.getEstatisticasGerais
);

router.get(
  '/page-views',
  authMiddleware,
  adminMiddleware,
  celebrate(analyticsValidation.getPageViewsStats),
  analyticsController.getPageViewsStats
);

router.get(
  '/eventos',
  authMiddleware,
  adminMiddleware,
  celebrate(analyticsValidation.getEventosPorTipo),
  analyticsController.getEventosPorTipo
);

router.get(
  '/sessoes',
  authMiddleware,
  adminMiddleware,
  celebrate(analyticsValidation.getSessoesStats),
  analyticsController.getSessoesStats
);

router.get(
  '/atividade-hora',
  authMiddleware,
  adminMiddleware,
  celebrate(analyticsValidation.getAtividadePorHora),
  analyticsController.getAtividadePorHora
);

router.get(
  '/crescimento-usuarios',
  authMiddleware,
  adminMiddleware,
  celebrate(analyticsValidation.getCrescimentoUsuarios),
  analyticsController.getCrescimentoUsuarios
);

module.exports = router;

