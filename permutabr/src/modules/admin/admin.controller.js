// /src/modules/admin/admin.controller.js

const adminService = require('./admin.service');
const perfLogger = require('../../core/utils/performance-logger');

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
  getPermutasConcluidas: handleRequest(() => adminService.getPermutasConcluidas(), 200),
  getProblemaRelatos: handleRequest((req) => adminService.getProblemaRelatos(req.query), 200),
  atualizarProblemaRelatoStatus: handleRequest(
    (req) => adminService.atualizarProblemaRelatoStatus(
      parseInt(req.params.id, 10),
      req.body.status,
      req.user?.id || null,
      req.body.resolucao || null
    ),
    200
  ),
  getSugestoes: handleRequest(() => adminService.getSugestoes(), 200),
  aprovarSugestao: handleRequest((req) => adminService.aprovarSugestao(req.params.id), 200),
  rejeitarSugestao: handleRequest((req) => adminService.rejeitarSugestao(req.params.id), 200),
  getVerificacoes: handleRequest(() => adminService.getVerificacoes(), 200),
  verificarPolicial: handleRequest((req) => adminService.verificarPolicial(req.params.id), 200),
  rejeitarPolicial: handleRequest((req) => adminService.rejeitarPolicial(req.params.id), 200),
  getAllPoliciais: handleRequest((req) => adminService.getAllPoliciais(req.query), 200),
  getPolicialDetalhes: handleRequest(
    (req) => adminService.getPolicialDetalhes(parseInt(req.params.id, 10)),
    200
  ),
  updatePolicial: handleRequest(
    (req) => adminService.updatePolicial(req.params.id, req.body, req.user.id),
    200
  ),
  getConfiguracoes: handleRequest(() => adminService.getConfiguracoes(), 200),
  updateConfiguracoes: handleRequest((req) => adminService.updateConfiguracoes(req.body), 200),
  getPremiumUsers: handleRequest((req) => adminService.getPremiumUsers(req.query), 200),
  deletePolicial: handleRequest(
    (req) => adminService.deletePolicial(req.params.id, req.user.id),
    200
  ),
  sendBulkEmail: handleRequest(
    (req) => adminService.sendBulkEmail(req.body),
    200
  ),
  getPerformanceLogs: handleRequest((req) => {
    const limit = parseInt(req.query.limit, 10) || 100;
    const module = req.query.module || null;
    return perfLogger.getRecent({ limit, module });
  }, 200),
};