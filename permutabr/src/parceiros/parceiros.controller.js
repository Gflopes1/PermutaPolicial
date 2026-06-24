// /src/modules/parceiros/parceiros.controller.js

const parceirosService = require('./parceiros.service');

const handleRequest = (servicePromise, successStatus) => async (req, res, next) => {
  try {
    const result = await servicePromise(req);
    res.status(successStatus).json({ status: 'success', data: result });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getAll: handleRequest(() => parceirosService.getAll(), 200),
  getById: handleRequest((req) => parceirosService.getById(req.params.id), 200),
  create: handleRequest((req) => parceirosService.create(req.body), 201),
  update: handleRequest((req) => parceirosService.update(req.params.id, req.body), 200),
  delete: handleRequest((req) => parceirosService.delete(req.params.id), 200),
  getConfig: handleRequest(() => parceirosService.getConfig(), 200),
  updateConfig: handleRequest((req) => parceirosService.updateConfig(req.body.exibir_card), 200),
};

