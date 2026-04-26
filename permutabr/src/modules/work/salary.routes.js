// /src/modules/work/salary.routes.js

const express = require('express');
const { celebrate } = require('celebrate');
const salaryValidation = require('./salary.validation');
const salaryController = require('./salary.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');

const router = express.Router();

router.use(authMiddleware);

// GET /api/salary/settings
router.get('/settings', salaryController.getSettings);

// PUT /api/salary/settings
router.put(
  '/settings',
  celebrate(salaryValidation.updateSettings),
  salaryController.updateSettings
);

// GET /api/salary/preview?month=MM&year=YYYY
router.get(
  '/preview',
  celebrate(salaryValidation.previewMonth),
  salaryController.previewMonth
);

// POST /api/salary/generate?month=MM&year=YYYY
router.post(
  '/generate',
  celebrate(salaryValidation.generateMonth),
  salaryController.generateMonth
);

// GET /api/salary/result?month=MM&year=YYYY
router.get(
  '/result',
  celebrate(salaryValidation.previewMonth),
  salaryController.getResult
);

// GET /api/salary/results?limit=12
router.get('/results', salaryController.getAllResults);

// GET /api/salary/export?month=MM&year=YYYY&format=pdf
router.get(
  '/export',
  celebrate(salaryValidation.exportMonth),
  salaryController.exportMonth
);

module.exports = router;


