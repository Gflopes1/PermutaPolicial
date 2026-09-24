// /src/modules/permutas/permutas.routes.js

const express = require('express');
const rateLimit = require('express-rate-limit');
const { celebrate } = require('celebrate');
const permutasValidation = require('./permutas.validation');
const permutasController = require('./permutas.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');

const router = express.Router();

const matchesLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    status: 'error',
    message: 'Muitas buscas de permutas. Aguarde um momento e tente novamente.',
  },
});

const previewLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 12,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    status: 'error',
    message: 'Muitas simulações. Aguarde um momento e tente novamente.',
  },
});

const statsLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    status: 'error',
    message: 'Muitas requisições. Aguarde um momento.',
  },
});

router.get(
  '/matches',
  authMiddleware,
  matchesLimiter,
  celebrate(permutasValidation.findMatches),
  permutasController.findMatches
);

router.get(
  '/metricas',
  authMiddleware,
  matchesLimiter,
  permutasController.getMetricas
);

router.post(
  '/preview-simulacao',
  previewLimiter,
  celebrate(permutasValidation.previewSimulacao),
  permutasController.previewSimulacao
);

router.get(
  '/stats-public',
  statsLimiter,
  permutasController.publicStats
);

module.exports = router;
