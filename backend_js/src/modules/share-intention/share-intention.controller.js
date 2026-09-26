// /src/modules/share-intention/share-intention.controller.js

const shareIntentionService = require('./share-intention.service');

module.exports = {
  async getShareLanding(req, res, next) {
    try {
      const { code } = req.params;
      const intencaoId = req.query.i ? parseInt(req.query.i, 10) : null;
      
      const html = await shareIntentionService.buildShareLandingHTML(code, intencaoId);
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      res.send(html);
    } catch (error) {
      next(error);
    }
  },

  async getPreviewImage(req, res, next) {
    try {
      const { code } = req.params;
      const intencaoId = req.query.i ? parseInt(req.query.i, 10) : null;
      
      const imageBuffer = await shareIntentionService.generatePreviewImage(code, intencaoId);
      
      res.setHeader('Content-Type', 'image/png');
      res.setHeader('Cache-Control', 'public, max-age=86400'); // 24h cache
      res.send(imageBuffer);
    } catch (error) {
      next(error);
    }
  },
};
