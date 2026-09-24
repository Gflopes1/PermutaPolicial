const express = require('express');
const { celebrate, Joi, Segments } = require('celebrate');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const pushController = require('./push.controller');

const router = express.Router();

router.use(authMiddleware);

router.post(
  '/register',
  celebrate({
    [Segments.BODY]: Joi.object({
      token: Joi.string().min(20).max(512).required(),
      platform: Joi.string().valid('android', 'ios', 'web').optional(),
    }),
  }),
  pushController.register
);

router.post(
  '/unregister',
  celebrate({
    [Segments.BODY]: Joi.object({
      token: Joi.string().min(20).max(512).required(),
    }),
  }),
  pushController.unregister
);

router.get('/status', pushController.status);

router.post('/test', pushController.test);

module.exports = router;
