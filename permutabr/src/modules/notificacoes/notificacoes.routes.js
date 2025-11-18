// /src/modules/notificacoes/notificacoes.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const notificacoesController = require('./notificacoes.controller');
const notificacoesValidation = require('./notificacoes.validation');
const authMiddleware = require('../../core/middlewares/auth.middleware');

const router = express.Router();

// Todas as rotas requerem autenticação
router.use(authMiddleware);

// Rotas específicas devem vir antes das rotas com parâmetros
router.get('/count', notificacoesController.countNaoLidas);
router.put('/marcar-todas-lidas', notificacoesController.marcarTodasComoLidas);
router.post('/solicitar-contato', celebrate(notificacoesValidation.criarSolicitacaoContato), notificacoesController.criarSolicitacaoContato);

// Rotas com parâmetros
router.get('/', notificacoesController.getNotificacoes);
router.post('/:id/responder', celebrate(notificacoesValidation.responderSolicitacaoContato), notificacoesController.responderSolicitacaoContato);
router.put('/:id/lida', notificacoesController.marcarComoLida);
router.delete('/:id', notificacoesController.delete);

module.exports = router;

