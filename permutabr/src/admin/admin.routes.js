// /src/modules/admin/admin.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const adminValidation = require('./admin.validation');
const adminController = require('./admin.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const adminMiddleware = require('../../core/middlewares/admin.middleware');
const embaixadorMiddleware = require('../../core/middlewares/embaixador.middleware');

const router = express.Router();

// Aplica os middlewares de autenticação e autorização a todas as rotas de admin
router.use(authMiddleware, adminMiddleware);

// Rota de Estatísticas
router.get('/estatisticas', adminController.getEstatisticas);
router.get('/permutas-concluidas', adminController.getPermutasConcluidas);
router.get('/problemas-relatos', adminController.getProblemaRelatos);
router.put(
  '/problemas-relatos/:id/status',
  celebrate(adminValidation.atualizarProblemaRelatoStatus),
  adminController.atualizarProblemaRelatoStatus
);

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
router.get(
  '/policiais',
  celebrate(adminValidation.getAllPoliciais),
  adminController.getAllPoliciais
);
router.get(
  '/policiais/:id/detalhes',
  celebrate(adminValidation.getPolicialDetalhes),
  adminController.getPolicialDetalhes
);
router.put(
  '/policiais/:id',
  celebrate(adminValidation.updatePolicial),
  adminController.updatePolicial
);
router.delete(
  '/policiais/:id',
  embaixadorMiddleware,
  celebrate(adminValidation.deletePolicial),
  adminController.deletePolicial
);
router.post(
  '/email/broadcast',
  embaixadorMiddleware,
  celebrate(adminValidation.sendBulkEmail),
  adminController.sendBulkEmail
);

// Rotas de configurações
router.get('/configuracoes', adminController.getConfiguracoes);
router.put('/configuracoes', adminController.updateConfiguracoes);

// Rotas de usuários premium
router.get('/premium', adminController.getPremiumUsers);

// Logs de performance (PI, MAPA, etc.)
router.get('/performance-logs', adminController.getPerformanceLogs);

module.exports = router;