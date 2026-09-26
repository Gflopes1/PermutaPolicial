// /src/modules/share-intention/share-intention.controller.js

const shareIntentionService = require('./share-intention.service');
const { applyFlutterWebHeaders } = require('../../core/utils/flutterWebHeaders');

module.exports = {
  async getShareLanding(req, res, next) {
    try {
      const { html, flutter } = await shareIntentionService.buildShareLandingHTML(
        req.params.code,
        req.query.i,
        req
      );
      if (flutter) {
        applyFlutterWebHeaders(res);
      } else {
        res.setHeader('Content-Type', 'text/html; charset=utf-8');
        res.setHeader('Cache-Control', 'no-cache');
      }
      res.setHeader('X-Robots-Tag', 'noindex, follow');
      res.send(html);
    } catch (error) {
      next(error);
    }
  },

  async getPreviewImage(req, res, next) {
    try {
      const imageBuffer = await shareIntentionService.generatePreviewImage(req.params.code, req.query.i);
      res.setHeader('Content-Type', 'image/png');
      // 1h: a intenção pode mudar; crawlers (WhatsApp) fazem cache próprio
      res.setHeader('Cache-Control', 'public, max-age=3600');
      res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
      res.setHeader('X-Robots-Tag', 'noindex');
      res.send(imageBuffer);
    } catch (error) {
      next(error);
    }
  },
};
