// /src/modules/problemas/problemas.controller.js

const problemasService = require('./problemas.service');

const handleRequest = (handler, statusCode = 200) => {
  return async (req, res, next) => {
    try {
      const result = await handler(req);
      res.status(statusCode).json({ status: 'success', data: result });
    } catch (error) {
      next(error);
    }
  };
};

module.exports = {
  criarRelato: handleRequest(async (req) => {
    return problemasService.criarRelato({
      usuario_id: req.user?.id || null,
      pagina: req.body.pagina,
      detalhes: req.body.detalhes,
      ip_address: req.ip || req.connection.remoteAddress,
      user_agent: req.get('user-agent'),
    });
  }, 201),

  buscarRelatos: handleRequest(async (req) => {
    const filtros = {
      status: req.query.status,
      pagina: req.query.pagina,
      usuario_id: req.query.usuario_id ? parseInt(req.query.usuario_id) : null,
      dataInicio: req.query.data_inicio || null,
      dataFim: req.query.data_fim || null,
      page: req.query.page ? parseInt(req.query.page) : 1,
      perPage: req.query.per_page ? parseInt(req.query.per_page) : 20,
    };
    return problemasService.buscarRelatos(filtros);
  }),

  buscarRelatoPorId: handleRequest(async (req) => {
    return problemasService.buscarRelatoPorId(parseInt(req.params.id));
  }),

  atualizarStatus: handleRequest(async (req) => {
    return problemasService.atualizarStatus(
      parseInt(req.params.id),
      req.body.status,
      req.user?.id || null,
      req.body.resolucao || null
    );
  }),

  getEstatisticas: handleRequest(async (req) => {
    return problemasService.getEstatisticas(
      req.query.data_inicio || null,
      req.query.data_fim || null
    );
  }),
};
