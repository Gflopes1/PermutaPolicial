const express = require('express');
const editalShareController = require('./editalShare.controller');

const router = express.Router();

// HTML com Open Graph dinâmico para /edital/:id (proxy via nginx)
router.get('/share/edital/:id', editalShareController.serveSharePage);

module.exports = router;
