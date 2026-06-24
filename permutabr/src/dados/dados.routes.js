// /src/modules/dados/dados.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const dadosValidation = require('./dados.validation');
const dadosController = require('./dados.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');

const router = express.Router();

// --- Rotas Públicas ---
router.get('/forcas', dadosController.getForcas);
router.get('/estados', dadosController.getEstados);

router.get(
  '/municipios/:estado_id',
  celebrate(dadosValidation.getMunicipiosPorEstado),
  dadosController.getMunicipiosPorEstado
);

router.get(
  '/unidades', // usa query params
  celebrate(dadosValidation.getUnidades),
  dadosController.getUnidades
);

// --- Rotas Privadas (exigem login) ---
router.post(
  '/unidades/sugerir',
  authMiddleware,
  celebrate(dadosValidation.sugerirUnidade),
  dadosController.sugerirUnidade
);

router.get(
  '/postos/:tipo_permuta',
  authMiddleware,
  celebrate(dadosValidation.getPostosPorForca),
  dadosController.getPostosPorForca
);

module.exports = router;