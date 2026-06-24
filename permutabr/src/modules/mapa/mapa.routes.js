// /src/modules/mapa/mapa.routes.js

const express = require('express');
const rateLimit = require('express-rate-limit');
const { celebrate } = require('celebrate');
const mapaValidation = require('./mapa.validation');
const mapaController = require('./mapa.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const optionalAuthMiddleware = require('../../core/middlewares/optionalAuth.middleware');

const router = express.Router();

const mapaDadosLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    status: 'error',
    message: 'Muitas requisições ao mapa. Aguarde um momento.',
  },
});

// Rota de dados do mapa com autenticação opcional
router.get(
  '/dados',
  mapaDadosLimiter,
  optionalAuthMiddleware,
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