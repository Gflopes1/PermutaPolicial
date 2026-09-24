// /src/modules/work/salary.controller.js

const salaryService = require('./salary.service');

const handleRequest = (servicePromise, successStatus) => async (req, res, next) => {
  try {
    const result = await servicePromise(req);
    res.status(successStatus).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  // GET /api/salary/settings
  getSettings: handleRequest(
    (req) => salaryService.getSettings(req.user.id),
    200
  ),

  // PUT /api/salary/settings
  updateSettings: handleRequest(
    (req) => salaryService.updateSettings(req.user.id, req.body),
    200
  ),

  // GET /api/salary/preview
  previewMonth: handleRequest(
    (req) => salaryService.previewMonth(
      req.user.id,
      parseInt(req.query.month),
      parseInt(req.query.year)
    ),
    200
  ),

  // POST /api/salary/generate
  generateMonth: handleRequest(
    (req) => salaryService.generateMonth(
      req.user.id,
      parseInt(req.query.month),
      parseInt(req.query.year)
    ),
    200
  ),

  // GET /api/salary/result
  getResult: handleRequest(
    (req) => salaryService.getResult(
      req.user.id,
      parseInt(req.query.month),
      parseInt(req.query.year)
    ),
    200
  ),

  // GET /api/salary/results
  getAllResults: handleRequest(
    (req) => salaryService.getAllResults(req.user.id, parseInt(req.query.limit) || 12),
    200
  ),

  // GET /api/salary/export
  exportMonth: async (req, res, next) => {
    try {
      const month = parseInt(req.query.month);
      const year = parseInt(req.query.year);
      const format = req.query.format || 'pdf';

      const result = await salaryService.getResult(req.user.id, month, year);
      if (!result) {
        return res.status(404).json({
          status: 'error',
          message: 'Resultado do mês não encontrado. Gere o resultado primeiro.',
        });
      }

      if (format === 'pdf') {
        // TODO: Implementar geração de PDF
        // Por enquanto, retorna JSON
        return res.json({
          status: 'success',
          data: result,
          message: 'Exportação PDF será implementada em breve. Dados retornados em JSON.'
        });
      } else {
        return res.status(400).json({
          status: 'error',
          message: 'Formato não suportado.',
        });
      }
    } catch (error) {
      next(error);
    }
  },
};

