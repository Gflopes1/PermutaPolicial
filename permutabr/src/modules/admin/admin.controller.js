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
  getAllPoliciais: handleRequest((req) => {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const search = req.query.search || '';
    return adminService.getAllPoliciais(page, limit, search);
  }, 200),
  getAllParceiros: handleRequest(() => adminService.getAllParceiros(), 200),
  createParceiro: handleRequest((req) => adminService.createParceiro(req.body), 201),
  updateParceiro: handleRequest((req) => adminService.updateParceiro(req.params.id, req.body), 200),
  deleteParceiro: handleRequest((req) => adminService.deleteParceiro(req.params.id), 200),
  getParceirosConfig: handleRequest(() => adminService.getParceirosConfig(), 200),
  updateParceirosConfig: handleRequest((req) => adminService.updateParceirosConfig(req.body.exibir_card), 200),
};