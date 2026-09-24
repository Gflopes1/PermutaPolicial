const ApiError = require('../../core/utils/ApiError');
const { applyFlutterWebHeaders } = require('../../core/utils/flutterWebHeaders');
const editalShareService = require('./editalShare.service');

module.exports = {
  async serveSharePage(req, res, next) {
    try {
      const editalId = parseInt(req.params.id, 10);
      if (!Number.isFinite(editalId) || editalId <= 0) {
        throw new ApiError(400, 'ID de edital inválido.');
      }

      const html = await editalShareService.buildShareHtml(editalId);
      if (!html) {
        throw new ApiError(404, 'Edital não encontrado.');
      }

      applyFlutterWebHeaders(res);
      res.send(html);
    } catch (error) {
      next(error);
    }
  },
};
