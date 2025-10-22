// /src/modules/policiais/policiais.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const policiaisValidation = require('./policiais.validation');
const policiaisController = require('./policiais.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');

const router = express.Router();

// Aplica o middleware de autenticação a todas as rotas deste arquivo
router.use(authMiddleware);

router.route('/me')
  .get(policiaisController.getMyProfile)
  .put(
    celebrate(policiaisValidation.updateMyProfile),
    policiaisController.updateMyProfile
  );

module.exports = router;