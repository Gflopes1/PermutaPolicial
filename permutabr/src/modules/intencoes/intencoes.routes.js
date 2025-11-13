// /src/modules/intencoes/intencoes.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const intencoesValidation = require('./intencoes.validation');
const intencoesController = require('./intencoes.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');

const router = express.Router();

// Protege todas as rotas de intenções com autenticação
router.use(authMiddleware);

router.route('/me')
  .get(intencoesController.getMyIntentions)
  .put(
    celebrate(intencoesValidation.updateMyIntentions),
    intencoesController.updateMyIntentions
  )
  .delete(intencoesController.deleteMyIntentions);

module.exports = router;