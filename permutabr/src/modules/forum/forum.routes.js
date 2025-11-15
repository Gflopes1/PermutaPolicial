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
  celebrate({ body: forumValidation.createTopico }),
  forumController.createTopico
);
router.put(
  '/topicos/:topicoId',
  celebrate({ body: forumValidation.updateTopico }),
  forumController.updateTopico
);
router.delete('/topicos/:topicoId', forumController.deleteTopico);

// Respostas
router.get('/topicos/:topicoId/respostas', forumController.getRespostas);
router.post(
  '/topicos/:topicoId/respostas',
  celebrate({ body: forumValidation.createResposta }),
  forumController.createResposta
);
router.put(
  '/respostas/:respostaId',
  celebrate({ body: forumValidation.updateResposta }),
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
// Listar itens pendentes (antes do middleware admin para teste)
router.get('/moderacao/topicos/pendentes', adminMiddleware, forumController.getTopicosPendentes);
router.get('/moderacao/respostas/pendentes', adminMiddleware, forumController.getRespostasPendentes);

// Moderação de Tópicos
router.post(
  '/moderacao/topicos/:topicoId/aprovar',
  adminMiddleware,
  celebrate(forumValidation.aprovarTopico),
  forumController.aprovarTopico
);
router.post(
  '/moderacao/topicos/:topicoId/rejeitar',
  adminMiddleware,
  celebrate(forumValidation.rejeitarTopico),
  forumController.rejeitarTopico
);
router.post(
  '/moderacao/topicos/:topicoId/fixar',
  adminMiddleware,
  celebrate(forumValidation.toggleFixarTopico),
  forumController.toggleFixarTopico
);
router.post(
  '/moderacao/topicos/:topicoId/bloquear',
  adminMiddleware,
  celebrate(forumValidation.toggleBloquearTopico),
  forumController.toggleBloquearTopico
);

// Moderação de Respostas
router.post(
  '/moderacao/respostas/:respostaId/aprovar',
  adminMiddleware,
  celebrate(forumValidation.aprovarResposta),
  forumController.aprovarResposta
);
router.post(
  '/moderacao/respostas/:respostaId/rejeitar',
  adminMiddleware,
  celebrate(forumValidation.rejeitarResposta),
  forumController.rejeitarResposta
);

module.exports = router;