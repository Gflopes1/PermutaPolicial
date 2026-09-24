const express = require('express');
const rateLimit = require('express-rate-limit');
const permutasInteligentesController = require('./permutas-inteligentes.controller');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const adminMiddleware = require('../../core/middlewares/admin.middleware');

const router = express.Router();

const matchesLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 15,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    status: 'error',
    message: 'Muitas buscas no motor inteligente. Aguarde um momento.',
  },
});

router.get('/matches', authMiddleware, matchesLimiter, permutasInteligentesController.findMatches);
router.get('/summary', authMiddleware, matchesLimiter, permutasInteligentesController.getSummary);

router.get('/admin/graph', authMiddleware, adminMiddleware, permutasInteligentesController.getAdminGraph);
router.get('/admin/graph-poster', authMiddleware, adminMiddleware, permutasInteligentesController.getAdminGraphPoster);
router.post('/admin/rebuild-graph', authMiddleware, adminMiddleware, permutasInteligentesController.rebuildAdminGraph);

module.exports = router;
