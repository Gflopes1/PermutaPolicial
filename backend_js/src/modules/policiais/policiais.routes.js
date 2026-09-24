// /src/modules/policiais/policiais.routes.js

const express = require('express');
const path = require('path');
const multer = require('multer');
const rateLimit = require('express-rate-limit');
const { celebrate } = require('celebrate');
const policiaisValidation = require('./policiais.validation');
const policiaisController = require('./policiais.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const { validateImageMagicBytes } = require('../mapa-tatico/mapa-tatico-security.utils');
const ApiError = require('../../core/utils/ApiError');

const router = express.Router();

const uploadLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Muitos uploads de foto. Tente novamente mais tarde.',
});

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowedExt = ['jpeg', 'jpg', 'png', 'webp', 'heic', 'heif'];
    const ext = path.extname(file.originalname || '').toLowerCase().replace(/^\./, '');
    const mime = (file.mimetype || '').toLowerCase();
    const ok =
      allowedExt.includes(ext) ||
      mime.startsWith('image/') ||
      mime === 'application/octet-stream' ||
      mime === '';
    if (ok) return cb(null, true);
    cb(new Error('Apenas imagens são permitidas (JPEG, PNG, WEBP, HEIC)'));
  },
});

function validateUploadedImage(req, res, next) {
  if (!req.file?.buffer) return next();
  try {
    validateImageMagicBytes(req.file.buffer);
    next();
  } catch (error) {
    next(error instanceof ApiError ? error : new ApiError(400, 'Arquivo de imagem inválido.'));
  }
}

router.use(authMiddleware);

router.route('/me')
  .get(policiaisController.getMyProfile)
  .put(
    celebrate(policiaisValidation.updateMyProfile),
    policiaisController.updateMyProfile
  );

router.post(
  '/me/photo',
  uploadLimiter,
  upload.single('photo'),
  validateUploadedImage,
  policiaisController.uploadMyProfilePhoto
);

router.delete('/me/photo', policiaisController.deleteMyProfilePhoto);

module.exports = router;
