// /src/modules/forum/forum.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const forumController = require('./forum.controller');
const forumValidation = require('./forum.validation');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const adminMiddleware = require('../../core/middlewares/admin.middleware');

const router = express.Router();

// Rotas públicas
router.get('/categorias', forumController.getCategorias);

// Rotas que requerem autenticação
router.use(authMiddleware);

// Tópicos
router.get('/topicos', forumController.getTopicos);
router.get('/topicos/search', forumController.searchTopicos);
router.get('/topicos/:topicoId', forumController.getTopico);
router.post(
  '/topicos',
  celebrate(forumValidation.createTopico),
  forumController.createTopico
);
router.put(
  '/topicos/:topicoId',
  celebrate(forumValidation.updateTopico),
  forumController.updateTopico
);
router.delete('/topicos/:topicoId', forumController.deleteTopico);

// Respostas
router.get('/topicos/:topicoId/respostas', forumController.getRespostas);
router.post(
  '/topicos/:topicoId/respostas',
  celebrate(forumValidation.createResposta),
  forumController.createResposta
);
router.put(
  '/respostas/:respostaId',
  celebrate(forumValidation.updateResposta),
  forumController.updateResposta
);
router.delete('/respostas/:respostaId', forumController.deleteResposta);

// Reações
router.post(
  '/reacoes',
  celebrate(forumValidation.toggleReacao),
  forumController.toggleReacao
);
router.get('/reacoes', forumController.getReacoes);

// Rotas de Moderação (apenas para administradores)
router.use('/moderacao', authMiddleware, adminMiddleware);

// Moderação de Tópicos
router.post(
  '/moderacao/topicos/:topicoId/aprovar',
  celebrate(forumValidation.aprovarTopico),
  forumController.aprovarTopico
);
router.post(
  '/moderacao/topicos/:topicoId/rejeitar',
  celebrate(forumValidation.rejeitarTopico),
  forumController.rejeitarTopico
);
router.post(
  '/moderacao/topicos/:topicoId/fixar',
  celebrate(forumValidation.toggleFixarTopico),
  forumController.toggleFixarTopico
);
router.post(
  '/moderacao/topicos/:topicoId/bloquear',
  celebrate(forumValidation.toggleBloquearTopico),
  forumController.toggleBloquearTopico
);

// Moderação de Respostas
router.post(
  '/moderacao/respostas/:respostaId/aprovar',
  celebrate(forumValidation.aprovarResposta),
  forumController.aprovarResposta
);
router.post(
  '/moderacao/respostas/:respostaId/rejeitar',
  celebrate(forumValidation.rejeitarResposta),
  forumController.rejeitarResposta
);

// Listar itens pendentes
router.get('/moderacao/topicos/pendentes', forumController.getTopicosPendentes);
router.get('/moderacao/respostas/pendentes', forumController.getRespostasPendentes);

module.exports = router;

