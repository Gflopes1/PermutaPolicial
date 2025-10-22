// /src/modules/permutas/permutas.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const permutasValidation = require('./permutas.validation');
const permutasController = require('./permutas.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');

const router = express.Router();

router.get(
  '/matches',
  authMiddleware,
  celebrate(permutasValidation.findMatches),
  permutasController.findMatches
);

module.exports = router;