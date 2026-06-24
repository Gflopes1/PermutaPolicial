// /src/modules/dados/dados.controller.js

const dadosService = require('./dados.service');

// Usamos o mesmo padrão de handleRequest para manter a consistência
const handleRequest = (servicePromise, successStatus) => async (req, res, next) => {
  try {
    const result = await servicePromise(req);
    res.status(successStatus).json({ status: 'success', data: result });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getForcas: handleRequest(() => dadosService.getForcas(), 200),
  getEstados: handleRequest(() => dadosService.getEstados(), 200),
  getMunicipiosPorEstado: handleRequest((req) => dadosService.getMunicipiosByEstadoId(req.params.estado_id), 200),
  getUnidades: handleRequest((req) => dadosService.getUnidades(req.query), 200),
  sugerirUnidade: handleRequest((req) => dadosService.sugerirUnidade(req.user.id, req.body), 201),
  getPostosPorForca: handleRequest((req) => dadosService.getPostosByForca(req.params.tipo_permuta), 200),
};