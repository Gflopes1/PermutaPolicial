const express = require('express');
const paymentsController = require('./payments.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const adminMiddleware = require('../../core/middlewares/admin.middleware');
const premiumMiddleware = require('../../core/middlewares/premium.middleware');

const router = express.Router();

// Middleware para capturar o body bruto (importante para validação de assinatura)
router.post(
  '/webhook/:provider?',
  express.raw({ type: 'application/json', verify: (req, res, buf) => { 
    req.rawBody = buf.toString('utf8');
    req.body = JSON.parse(buf.toString('utf8')); // Também parseia para req.body
  } }),
  paymentsController.processWebhook
);

router.get(
  '/subscription',
  authMiddleware,
  paymentsController.getUserSubscription
);

router.post(
  '/subscription/cancel',
  authMiddleware,
  paymentsController.cancelSubscription
);

router.get(
  '/webhook-logs',
  authMiddleware,
  adminMiddleware,
  paymentsController.getWebhookLogs
);

router.post(
  '/webhook-logs/:id/retry',
  authMiddleware,
  adminMiddleware,
  paymentsController.retryWebhook
);

module.exports = router;

