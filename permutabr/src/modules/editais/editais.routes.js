const express = require('express');
const { celebrate } = require('celebrate');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const editalAccessMiddleware = require('./editalAccess.middleware');
const editaisValidation = require('./editais.validation');
const editaisController = require('./editais.controller');

const router = express.Router();

router.get('/whatsapp-config', authMiddleware, editaisController.getWhatsappConfig);

router.get(
  '/',
  authMiddleware,
  celebrate(editaisValidation.listEditais),
  editaisController.listEditais
);

router.get('/:id', authMiddleware, editaisController.getEdital);

router.get(
  '/:id/dados-tela',
  authMiddleware,
  editalAccessMiddleware,
  editaisController.getDadosTela
);

router.post(
  '/:id/intencoes',
  authMiddleware,
  editalAccessMiddleware,
  celebrate(editaisValidation.salvarIntencoes),
  editaisController.salvarIntencoes
);

router.get(
  '/:id/analise-vaga/:vagaId',
  authMiddleware,
  editalAccessMiddleware,
  editaisController.analisarVaga
);

module.exports = router;
