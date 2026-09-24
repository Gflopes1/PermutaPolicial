// /src/api/index.js

const express = require('express');
const path = require('path');
const router = express.Router();

const graphPosterHtmlPath = path.join(__dirname, '../public/grafo-permutas-poster.html');
const graphViewerHtmlPath = path.join(__dirname, '../public/graph-viewer.html');
const graphPosterCsp = [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com",
    "style-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com https://fonts.googleapis.com",
    "img-src 'self' data: https:",
    "connect-src 'self'",
    "font-src 'self' https://cdnjs.cloudflare.com https://fonts.gstatic.com",
].join('; ');

// Importa os roteadores de cada módulo
const authRoutes = require('../modules/auth/auth.routes');
const policiaisRoutes = require('../modules/policiais/policiais.routes');
const intencoesRoutes = require('../modules/intencoes/intencoes.routes');
const permutasRoutes = require('../modules/permutas/permutas.routes');
const permutasInteligentesRoutes = require('../modules/permutas-inteligentes/permutas-inteligentes.routes');
const dadosRoutes = require('../modules/dados/dados.routes');
const mapaRoutes = require('../modules/mapa/mapa.routes');
const mapaTaticoRoutes = require('../modules/mapa-tatico/mapa-tatico.routes');
const mapaTaticoAdminRoutes = require('../modules/mapa-tatico/admin/mapa-tatico-admin.routes');
const adminRoutes = require('../modules/admin/admin.routes');
const editaisRoutes = require('../modules/editais/editais.routes');
const editaisAdminRoutes = require('../modules/editais/editais-admin.routes');
const parceirosRoutes = require('../modules/parceiros/parceiros.routes');
const chatRoutes = require('../modules/chat/chat.routes');
const forumRoutes = require('../modules/forum/forum.routes');
const marketplaceRoutes = require('../modules/marketplace/marketplace.routes');
const notificacoesRoutes = require('../modules/notificacoes/notificacoes.routes');
const analyticsRoutes = require('../modules/analytics/analytics.routes');
const configuracoesRoutes = require('../modules/configuracoes/configuracoes.routes');
const workRoutes = require('../modules/work/work.routes');
const presetsRoutes = require('../modules/work/presets.routes');
const salaryRoutes = require('../modules/work/salary.routes');
const questionsRoutes = require('../modules/questions/questions.routes');
const simuladosRoutes = require('../modules/questions/simulados.routes');
const commentsRoutes = require('../modules/questions/comments.routes');
const paymentsRoutes = require('../modules/questions/payments.routes');
const problemasRoutes = require('../modules/problemas/problemas.routes');
const pushRoutes = require('../modules/push/push.routes');
const mediaRoutes = require('../modules/media/media.routes');
const consultoriaJuridicaRoutes = require('../modules/consultoria-juridica/consultoria-juridica.routes');
const referralRoutes = require('../modules/referral/referral.routes');
const verificacaoOcrRoutes = require('../modules/verificacao-ocr/verificacao-ocr.routes');

router.get('/', (req, res) => {
    res.json({
        message: 'Bem-vindo à API do Permuta Policial v2',
        status: 'online'
    });
});

// Pôster do grafo admin — público (auth via token na query; dados via API autenticada)
router.get('/grafo-permutas-poster.html', (req, res, next) => {
    res.setHeader('Content-Security-Policy', graphPosterCsp);
    res.sendFile(graphPosterHtmlPath, (err) => {
        if (err) next(err);
    });
});

// Viewer interativo do grafo (mesmo motor, vis-network)
router.get('/graph-viewer.html', (req, res, next) => {
    res.setHeader('Content-Security-Policy', graphPosterCsp);
    res.sendFile(graphViewerHtmlPath, (err) => {
        if (err) next(err);
    });
});

// Proxy público de imagens R2 (sem auth — keys aleatórias, prefixos restritos)
router.use('/', mediaRoutes);

// Define os prefixos para cada conjunto de rotas
router.use('/auth', authRoutes);
router.use('/policiais', policiaisRoutes);
router.use('/intencoes', intencoesRoutes);
router.use('/permutas', permutasRoutes);
router.use('/permutas-inteligentes', permutasInteligentesRoutes);
router.use('/dados', dadosRoutes);
router.use('/mapa', mapaRoutes);
router.use('/mapa-tatico', mapaTaticoRoutes);
router.use('/admin/mapa-tatico', mapaTaticoAdminRoutes);
router.use('/admin', adminRoutes);
router.use('/admin/editais', editaisAdminRoutes);
router.use('/editais', editaisRoutes);
router.use('/parceiros', parceirosRoutes);
router.use('/consultoria-juridica', consultoriaJuridicaRoutes);
router.use('/chat', chatRoutes);
router.use('/forum', forumRoutes);
router.use('/marketplace', marketplaceRoutes);
router.use('/notificacoes', notificacoesRoutes);
router.use('/analytics', analyticsRoutes);
router.use('/configuracoes', configuracoesRoutes);
router.use('/work', workRoutes);
router.use('/presets', presetsRoutes);
router.use('/salary', salaryRoutes);
router.use('/questions', questionsRoutes);
router.use('/simulado', simuladosRoutes);
router.use('/comments', commentsRoutes);
router.use('/payments', paymentsRoutes);
router.use('/problemas', problemasRoutes);
router.use('/push', pushRoutes);
router.use('/referral', referralRoutes);
router.use('/verificacao', verificacaoOcrRoutes);

module.exports = router;