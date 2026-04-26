const express = require('express');
const { celebrate } = require('celebrate');
const commentsController = require('./comments.controller');
const commentsValidation = require('./comments.validation');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const adminMiddleware = require('../../core/middlewares/admin.middleware');

const router = express.Router();

router.get(
  '/questions/:id/comments',
  celebrate(commentsValidation.getComments),
  commentsController.getComments
);

router.get(
  '/:id/replies',
  celebrate(commentsValidation.getReplies),
  commentsController.getReplies
);

router.post(
  '/questions/:id/comments',
  authMiddleware,
  celebrate(commentsValidation.createComment),
  commentsController.createComment
);

router.put(
  '/:id',
  authMiddleware,
  celebrate(commentsValidation.updateComment),
  commentsController.updateComment
);

router.delete(
  '/:id',
  authMiddleware,
  celebrate(commentsValidation.deleteComment),
  commentsController.deleteComment
);

router.post(
  '/:id/like',
  authMiddleware,
  celebrate(commentsValidation.toggleLike),
  commentsController.toggleLike
);

router.post(
  '/:id/report',
  authMiddleware,
  celebrate(commentsValidation.reportComment),
  commentsController.reportComment
);

router.post(
  '/:id/moderate',
  authMiddleware,
  adminMiddleware,
  celebrate(commentsValidation.moderateComment),
  commentsController.moderateComment
);

module.exports = router;


