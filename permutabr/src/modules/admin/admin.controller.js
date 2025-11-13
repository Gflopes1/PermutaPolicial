// /src/modules/admin/admin.controller.js

const adminService = require('./admin.service');

const handleRequest = (servicePromise, successStatus) => async (req, res, next) => {
  try {
    const result = await servicePromise(req);
    res.status(successStatus).json({ status: 'success', data: result });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getEstatisticas: handleRequest(() => adminService.getEstatisticas(), 200),
  getSugestoes: handleRequest(() => adminService.getSugestoes(), 200),
  aprovarSugestao: handleRequest((req) => adminService.aprovarSugestao(req.params.id), 200),
  rejeitarSugestao: handleRequest((req) => adminService.rejeitarSugestao(req.params.id), 200),
  getVerificacoes: handleRequest(() => adminService.getVerificacoes(), 200),
  verificarPolicial: handleRequest((req) => adminService.verificarPolicial(req.params.id), 200),
  rejeitarPolicial: handleRequest((req) => adminService.rejeitarPolicial(req.params.id), 200),
  getAllPoliciais: handleRequest((req) => adminService.getAllPoliciais(req.query), 200),
  updatePolicial: handleRequest((req) => adminService.updatePolicial(req.params.id, req.body), 200),
};