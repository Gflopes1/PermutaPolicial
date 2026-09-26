// /src/modules/share-intention/share-intention.routes.js

const express = require('express');
const router = express.Router();
const shareIntentionController = require('./share-intention.controller');

// Rota pública para landing page de compartilhamento com OG tags dinâmicas
// /r/:code?i=intencaoId
router.get('/:code', shareIntentionController.getShareLanding);

// Endpoint de geração de imagem preview (1200x630)
// /r/:code/preview.png?i=intencaoId
router.get('/:code/preview.png', shareIntentionController.getPreviewImage);

module.exports = router;
