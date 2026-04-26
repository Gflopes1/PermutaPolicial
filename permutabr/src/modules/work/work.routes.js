// /src/modules/work/work.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const workValidation = require('./work.validation');
const workController = require('./work.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');

const router = express.Router();

// Todas as rotas requerem autenticação (usuário gerencia seu próprio calendário)
router.use(authMiddleware);

// GET /api/work/month?month=MM&year=YYYY
router.get(
  '/month',
  celebrate(workValidation.getMonth),
  workController.getMonth
);

// POST /api/work/day
router.post(
  '/day',
  celebrate(workValidation.upsertDay),
  workController.upsertDay
);

// DELETE /api/work/day/:id
router.delete(
  '/day/:id',
  celebrate(workValidation.deleteDay),
  workController.deleteDay
);

// POST /api/work/apply-preset
router.post(
  '/apply-preset',
  celebrate(workValidation.applyPreset),
  workController.applyPreset
);

// GET /api/work/stats?month=MM&year=YYYY
router.get(
  '/stats',
  celebrate(workValidation.getMonth),
  workController.getStats
);

module.exports = router;


