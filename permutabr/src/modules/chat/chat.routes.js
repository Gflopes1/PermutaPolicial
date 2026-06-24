// /src/modules/chat/chat.routes.js

const express = require('express');
const rateLimit = require('express-rate-limit');
const { celebrate } = require('celebrate');
const chatController = require('./chat.controller');
const chatValidation = require('./chat.validation');
const authMiddleware = require('../../core/middlewares/auth.middleware');

const router = express.Router();

const mensagemLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    status: 'error',
    message: 'Muitas mensagens enviadas. Aguarde um momento.',
  },
});

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
  mensagemLimiter,
  celebrate(chatValidation.createMensagem),
  chatController.createMensagem
);

// Inicia uma nova conversa com outro usuário
router.post(
  '/conversas',
  celebrate(chatValidation.iniciarConversa),
  chatController.iniciarConversa
);

// Marca mensagens de uma conversa como lidas
router.put('/conversas/:conversaId/lidas', chatController.marcarComoLidas);

// Aceita compartilhar dados em conversa anônima
router.put('/conversas/:conversaId/compartilhar-dados', chatController.aceitarCompartilharDados);

// Perfil público do contato na conversa (respeita anonimato)
router.get('/conversas/:conversaId/contato', chatController.getPerfilContato);

// Exclui uma conversa
router.delete('/conversas/:conversaId', chatController.excluirConversa);

// Conta mensagens não lidas do usuário
router.get('/mensagens/nao-lidas', chatController.getMensagensNaoLidas);

module.exports = router;

