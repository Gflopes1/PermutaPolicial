// /src/modules/configuracoes/configuracoes.routes.js

const express = require('express');
const configuracoesController = require('./configuracoes.controller');

const router = express.Router();

// Rota pública para buscar nota de atualização
router.get('/nota-atualizacao', configuracoesController.getNotaAtualizacao);

module.exports = router;

