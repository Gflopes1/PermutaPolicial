// /src/modules/chat/chat.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const chatController = require('./chat.controller');
const chatValidation = require('./chat.validation');
const authMiddleware = require('../../core/middlewares/auth.middleware');

const router = express.Router();

// Aplica o middleware de autenticação a todas as rotas
router.use(authMiddleware);

// Lista todas as conversas do usuário
router.get('/conversas', chatController.getConversas);

// Busca informações de uma conversa específica
router.get('/conversas/:conversaId', chatController.getConversa);

// Busca mensagens de uma conversa
router.get('/conversas/:conversaId/mensagens', chatController.getMensagens);

// Cria uma nova mensagem
router.post(
  '/conversas/:conversaId/mensagens',
  celebrate({ body: chatValidation.createMensagem }), // <-- CORRIGIDO
  chatController.createMensagem
);

// Inicia uma nova conversa com outro usuário
router.post(
  '/conversas',
  celebrate({ body: chatValidation.iniciarConversa }), // <-- CORRIGIDO
  chatController.iniciarConversa
);

// Marca mensagens de uma conversa como lidas
router.put('/conversas/:conversaId/lidas', chatController.marcarComoLidas);

// Conta mensagens não lidas do usuário
router.get('/mensagens/nao-lidas', chatController.getMensagensNaoLidas);

module.exports = router;