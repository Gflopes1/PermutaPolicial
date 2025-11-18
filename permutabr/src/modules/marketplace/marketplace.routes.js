// /src/modules/marketplace/marketplace.routes.js

const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const marketplaceController = require('./marketplace.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const adminMiddleware = require('../../core/middlewares/admin.middleware');

const router = express.Router();

// Configuração do multer para upload de imagens
const uploadDir = path.join(__dirname, '../../../uploads/marketplace');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'marketplace-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|webp/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    if (mimetype && extname) {
      return cb(null, true);
    }
    cb(new Error('Apenas imagens são permitidas (JPEG, PNG, WEBP)'));
  }
});

// IMPORTANTE: Rotas de admin devem vir PRIMEIRO
router.use('/admin', authMiddleware, adminMiddleware);
router.get('/admin/todos', marketplaceController.getAllAdmin);
router.put('/admin/:id/aprovar', marketplaceController.aprovar);
router.put('/admin/:id/rejeitar', marketplaceController.rejeitar);
router.delete('/admin/:id', marketplaceController.deleteAdmin);

// Rotas autenticadas
router.post('/', authMiddleware, upload.array('fotos', 3), marketplaceController.create);
router.put('/:id', authMiddleware, upload.array('fotos', 3), marketplaceController.update);
router.delete('/:id', authMiddleware, marketplaceController.delete);

// Rotas públicas e específicas (devem vir ANTES das rotas com :id)
router.get('/usuario/:policialId', marketplaceController.getByUsuario);
router.get('/', marketplaceController.getAll);

// Rota com parâmetro dinâmico :id deve vir POR ÚLTIMO
router.get('/:id', marketplaceController.getById);

module.exports = router;