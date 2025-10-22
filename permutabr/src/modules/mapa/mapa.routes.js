// /src/modules/mapa/mapa.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const mapaValidation = require('./mapa.validation');
const mapaController = require('./mapa.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const optionalAuthMiddleware = require('../../core/middlewares/optionalAuth.middleware');

const router = express.Router();

// Rota de dados do mapa com autenticação opcional
router.get(
  '/dados',
  optionalAuthMiddleware, // Tenta autenticar, mas não falha se não houver token
  celebrate(mapaValidation.getMapData),
  mapaController.getMapData
);

// Rota de detalhes com autenticação obrigatória
router.get(
  '/detalhes-municipio',
  authMiddleware, // Exige um token válido
  celebrate(mapaValidation.getMunicipioDetails),
  mapaController.getMunicipioDetails
);

module.exports = router;