// /src/api/index.js

const express = require('express');
const router = express.Router();

// Importa os roteadores de cada módulo
const authRoutes = require('../modules/auth/auth.routes');
const policiaisRoutes = require('../modules/policiais/policiais.routes');
const intencoesRoutes = require('../modules/intencoes/intencoes.routes');
const permutasRoutes = require('../modules/permutas/permutas.routes');
const dadosRoutes = require('../modules/dados/dados.routes');
const mapaRoutes = require('../modules/mapa/mapa.routes');
const adminRoutes = require('../modules/admin/admin.routes');

router.get('/', (req, res) => {
    res.json({
        message: 'Bem-vindo à API do Permuta Policial v2',
        status: 'online'
    });
});

// Define os prefixos para cada conjunto de rotas
router.use('/auth', authRoutes);
router.use('/policiais', policiaisRoutes);
router.use('/intencoes', intencoesRoutes);
router.use('/permutas', permutasRoutes);
router.use('/dados', dadosRoutes);
router.use('/mapa', mapaRoutes);
router.use('/admin', adminRoutes);

module.exports = router;