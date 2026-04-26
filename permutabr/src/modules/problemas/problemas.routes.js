// /src/modules/problemas/problemas.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const problemasValidation = require('./problemas.validation');
const problemasController = require('./problemas.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const adminMiddleware = require('../../core/middlewares/admin.middleware');

const router = express.Router();

// Rota pública para criar relato (qualquer usuário pode relatar)
router.post(
  '/relato',
  celebrate(problemasValidation.criarRelato),
  problemasController.criarRelato
);

// Rotas protegidas (apenas autenticados podem ver seus próprios relatos)
router.get(
  '/relatos',
  authMiddleware,
  celebrate(problemasValidation.buscarRelatos),
  problemasController.buscarRelatos
);

router.get(
  '/relatos/:id',
  authMiddleware,
  celebrate(problemasValidation.buscarRelatoPorId),
  problemasController.buscarRelatoPorId
);

// Rotas de admin (apenas admins podem gerenciar todos os relatos)
router.put(
  '/relatos/:id/status',
  authMiddleware,
  adminMiddleware,
  celebrate(problemasValidation.atualizarStatus),
  problemasController.atualizarStatus
);

router.get(
  '/estatisticas',
  authMiddleware,
  adminMiddleware,
  celebrate(problemasValidation.getEstatisticas),
  problemasController.getEstatisticas
);

module.exports = router;
