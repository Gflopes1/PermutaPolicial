const consultoriaService = require('./consultoria-juridica.service');

const handleRequest = (serviceFn, successStatus = 200) => async (req, res, next) => {
  try {
    const result = await serviceFn(req);
    res.status(successStatus).json({ status: 'success', data: result });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  listPublic: handleRequest(() => consultoriaService.listPublic(), 200),
  getPublicById: handleRequest((req) => consultoriaService.getPublicById(req), 200),
  registerClick: handleRequest((req) => consultoriaService.registerClick(req), 201),
  listAdmin: handleRequest(() => consultoriaService.listAdmin(), 200),
  getAdminById: handleRequest((req) => consultoriaService.getAdminById(req), 200),
  createAdmin: handleRequest((req) => consultoriaService.createAdmin(req), 201),
  updateAdmin: handleRequest((req) => consultoriaService.updateAdmin(req), 200),
  deleteAdmin: handleRequest((req) => consultoriaService.deleteAdmin(req), 200),
  getClickStats: handleRequest(() => consultoriaService.getClickStats(), 200),
};
