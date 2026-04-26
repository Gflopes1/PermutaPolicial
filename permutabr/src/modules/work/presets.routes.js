// /src/modules/work/presets.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const presetsValidation = require('./presets.validation');
const presetsController = require('./presets.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');

const router = express.Router();

router.use(authMiddleware);

// GET /api/presets
router.get('/', presetsController.getPresets);

// GET /api/presets/:id
router.get('/:id', presetsController.getPresetById);

// POST /api/presets
router.post(
  '/',
  celebrate(presetsValidation.createPreset),
  presetsController.createPreset
);

// PUT /api/presets/:id
router.put(
  '/:id',
  celebrate(presetsValidation.updatePreset),
  presetsController.updatePreset
);

// DELETE /api/presets/:id
router.delete(
  '/:id',
  celebrate(presetsValidation.deletePreset),
  presetsController.deletePreset
);

module.exports = router;


