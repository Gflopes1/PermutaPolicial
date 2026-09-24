// /src/modules/configuracoes/configuracoes.routes.js

const express = require('express');
const configuracoesController = require('./configuracoes.controller');

const router = express.Router();

// Rota pública — config leve do app (interface do dashboard, etc.)
router.get('/app', configuracoesController.getAppConfig);

// Rota pública para buscar nota de atualização
router.get('/nota-atualizacao', configuracoesController.getNotaAtualizacao);

// Rota pública — dados de apoio ao projeto (PIX etc.)
router.get('/apoio', configuracoesController.getApoio);

module.exports = router;

