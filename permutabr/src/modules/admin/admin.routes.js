// /src/modules/admin/admin.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const adminValidation = require('./admin.validation');
const adminController = require('./admin.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const adminMiddleware = require('../../core/middlewares/admin.middleware');

const router = express.Router();

// Aplica os middlewares de autenticação e autorização a todas as rotas de admin
router.use(authMiddleware, adminMiddleware);

// Rota de Estatísticas
router.get('/estatisticas', adminController.getEstatisticas);

// Rotas de Sugestões de Unidades
router.get('/sugestoes', adminController.getSugestoes);
router.post(
  '/sugestoes/:id/aprovar',
  celebrate(adminValidation.processaSugestao),
  adminController.aprovarSugestao
);
router.post(
  '/sugestoes/:id/rejeitar',
  celebrate(adminValidation.processaSugestao),
  adminController.rejeitarSugestao
);

// Rotas de Verificação de Policiais
router.get('/verificacoes', adminController.getVerificacoes);
router.post(
  '/verificacoes/:id/verificar',
  celebrate(adminValidation.processaVerificacao),
  adminController.verificarPolicial
);
// Adicionando a rota para rejeitar, para completar a funcionalidade
router.post(
    '/verificacoes/:id/rejeitar',
    celebrate(adminValidation.processaVerificacao),
    adminController.rejeitarPolicial
);

// Rotas de gerenciamento de usuários
router.get('/policiais', adminController.getAllPoliciais);
router.put('/policiais/:id', adminController.updatePolicial);

module.exports = router;