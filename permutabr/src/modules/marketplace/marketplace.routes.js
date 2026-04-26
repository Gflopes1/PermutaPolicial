// /src/modules/marketplace/marketplace.routes.js

const express = require('express');
const multer = require('multer');
const path = require('path');
const marketplaceController = require('./marketplace.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const verifiedAuthMiddleware = require('../../core/middlewares/verifiedAuth.middleware');
const adminMiddleware = require('../../core/middlewares/admin.middleware');

const router = express.Router();

// Configuração do multer para upload de imagens em memória (para processar e enviar ao R2)
const upload = multer({
  storage: multer.memoryStorage(),
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
router.get('/admin/pendentes/count', marketplaceController.countPendentes);
router.put('/admin/:id/aprovar', marketplaceController.aprovar);
router.put('/admin/:id/rejeitar', marketplaceController.rejeitar);
router.delete('/admin/:id', marketplaceController.deleteAdmin);

// Rotas autenticadas (requerem conta verificada)
router.post('/', authMiddleware, verifiedAuthMiddleware, upload.array('fotos', 3), marketplaceController.create);
router.put('/:id', authMiddleware, verifiedAuthMiddleware, upload.array('fotos', 3), marketplaceController.update);
router.delete('/:id', authMiddleware, verifiedAuthMiddleware, marketplaceController.delete);

// Rotas públicas e específicas (devem vir ANTES das rotas com :id)
router.get('/usuario/:policialId', marketplaceController.getByUsuario);
router.get('/', marketplaceController.getAll);

// Rota com parâmetro dinâmico :id deve vir POR ÚLTIMO
router.get('/:id', marketplaceController.getById);

module.exports = router;