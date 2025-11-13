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
const novosSoldadosRoutes = require('../modules/novos-soldados/novos-soldados.routes');
const parceirosRoutes = require('../modules/parceiros/parceiros.routes');
const chatRoutes = require('../modules/chat/chat.routes');
const forumRoutes = require('../modules/forum/forum.routes');
const marketplaceRoutes = require('../modules/marketplace/marketplace.routes');

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
router.use('/novos-soldados', novosSoldadosRoutes);
router.use('/parceiros', parceirosRoutes);
router.use('/chat', chatRoutes);
router.use('/forum', forumRoutes);
router.use('/marketplace', marketplaceRoutes);

module.exports = router;