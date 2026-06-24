// /src/modules/parceiros/parceiros.routes.js

const express = require('express');
const parceirosController = require('./parceiros.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const adminMiddleware = require('../../core/middlewares/admin.middleware');

const router = express.Router();

// Rota pública para obter parceiros ativos
router.get('/', parceirosController.getConfig);

// Rotas de admin para gerenciar parceiros
router.use(authMiddleware, adminMiddleware);

router.get('/admin', parceirosController.getAll);
router.get('/admin/:id', parceirosController.getById);
router.post('/admin', parceirosController.create);
router.put('/admin/:id', parceirosController.update);
router.delete('/admin/:id', parceirosController.delete);
router.put('/admin/config', parceirosController.updateConfig);

module.exports = router;

