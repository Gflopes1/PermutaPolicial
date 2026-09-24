const express = require('express');
const path = require('path');
const multer = require('multer');
const { celebrate } = require('celebrate');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const adminMiddleware = require('../../core/middlewares/admin.middleware');
const { validateImageMagicBytes } = require('../mapa-tatico/mapa-tatico-security.utils');
const ApiError = require('../../core/utils/ApiError');
const verificacaoOcrValidation = require('./verificacao-ocr.validation');
const verificacaoOcrController = require('./verificacao-ocr.controller');

const router = express.Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 15 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowedExt = ['jpeg', 'jpg', 'png', 'webp'];
    const ext = path.extname(file.originalname || '').toLowerCase().replace(/^\./, '');
    const mime = (file.mimetype || '').toLowerCase();
    const ok = allowedExt.includes(ext) || mime.startsWith('image/') || mime === 'application/octet-stream';
    if (ok) return cb(null, true);
    cb(new Error('Apenas imagens são permitidas (JPEG, PNG, WEBP)'));
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

router.get(
  '/ocr/status',
  authMiddleware,
  verificacaoOcrController.getMyOcrStatus
);

router.post(
  '/ocr',
  authMiddleware,
  upload.single('imagem_redigida'),
  validateUploadedImage,
  celebrate(verificacaoOcrValidation.submitOcr),
  verificacaoOcrController.submitOcr
);

router.post(
  '/ocr/vision-recognize',
  authMiddleware,
  upload.single('imagem_ocr'),
  validateUploadedImage,
  verificacaoOcrController.recognizeVision
);

router.get(
  '/ocr/pendentes',
  authMiddleware,
  adminMiddleware,
  verificacaoOcrController.getPendingOcrReviews
);

router.post(
  '/ocr/pendentes/:id/aprovar',
  authMiddleware,
  adminMiddleware,
  celebrate(verificacaoOcrValidation.processOcrReview),
  verificacaoOcrController.approveOcrReview
);

router.post(
  '/ocr/pendentes/:id/rejeitar',
  authMiddleware,
  adminMiddleware,
  celebrate(verificacaoOcrValidation.processOcrReview),
  verificacaoOcrController.rejectOcrReview
);

module.exports = router;
