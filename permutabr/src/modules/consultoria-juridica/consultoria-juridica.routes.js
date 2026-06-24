const express = require('express');
const multer = require('multer');
const path = require('path');
const { celebrate } = require('celebrate');
const consultoriaController = require('./consultoria-juridica.controller');
const consultoriaValidation = require('./consultoria-juridica.validation');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const adminMiddleware = require('../../core/middlewares/admin.middleware');
const { validateImageMagicBytes } = require('../mapa-tatico/mapa-tatico-security.utils');
const ApiError = require('../../core/utils/ApiError');

const router = express.Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 12 * 1024 * 1024 },
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

// ========== ADMIN (rotas específicas antes de /:id) ==========
router.get('/admin/stats', authMiddleware, adminMiddleware, consultoriaController.getClickStats);
router.get('/admin/list', authMiddleware, adminMiddleware, consultoriaController.listAdmin);
router.get(
  '/admin/:id',
  authMiddleware,
  adminMiddleware,
  celebrate({ params: consultoriaValidation.paramsId }),
  consultoriaController.getAdminById
);
router.post(
  '/admin',
  authMiddleware,
  adminMiddleware,
  upload.single('photo'),
  validateUploadedImage,
  consultoriaController.createAdmin
);
router.put(
  '/admin/:id',
  authMiddleware,
  adminMiddleware,
  upload.single('photo'),
  validateUploadedImage,
  celebrate({ params: consultoriaValidation.paramsId }),
  consultoriaController.updateAdmin
);
router.delete(
  '/admin/:id',
  authMiddleware,
  adminMiddleware,
  celebrate({ params: consultoriaValidation.paramsId }),
  consultoriaController.deleteAdmin
);

// ========== PÚBLICO ==========
router.get('/', consultoriaController.listPublic);

router.post(
  '/:id/clique',
  authMiddleware,
  celebrate({ params: consultoriaValidation.paramsId, body: consultoriaValidation.registerClick }),
  consultoriaController.registerClick
);

router.get(
  '/:id',
  celebrate({ params: consultoriaValidation.paramsId }),
  consultoriaController.getPublicById
);

module.exports = router;
