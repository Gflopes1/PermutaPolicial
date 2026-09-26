// /src/modules/share-intention/share-intention.routes.js
// Montado em /r (server.js), antes de /api e do 404. nginx faz proxy de /r/ -> Node.

const express = require('express');
const router = express.Router();
const shareIntentionController = require('./share-intention.controller');

// Imagem preview (1200x630): /r/:code/preview.png?i=intencaoId
router.get('/:code/preview.png', shareIntentionController.getPreviewImage);

// Landing com OG dinâmico: /r/:code?i=intencaoId
router.get('/:code', shareIntentionController.getShareLanding);

module.exports = router;
