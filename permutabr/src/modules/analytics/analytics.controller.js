// /src/modules/analytics/analytics.controller.js

const analyticsService = require('./analytics.service');

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
  registrarEvento: handleRequest(async (req) => {
    return analyticsService.registrarEvento({
      usuario_id: req.user?.id || null,
      evento_tipo: req.body.evento_tipo,
      metadata: req.body.metadata || null,
      ip_address: req.ip || req.connection.remoteAddress,
      user_agent: req.get('user-agent'),
    });
  }, 201),

  registrarPageView: handleRequest(async (req) => {
    const result = await analyticsService.registrarPageView({
      usuario_id: req.user?.id || null,
      pagina: req.body.pagina,
      sessao_id: req.body.sessao_id,
      ip_address: req.ip || req.connection.remoteAddress,
      user_agent: req.get('user-agent'),
    });
    return { id: result.id };
  }, 201),

  atualizarTempoPermanencia: handleRequest(async (req) => {
    return analyticsService.atualizarTempoPermanencia(
      req.body.page_view_id,
      req.body.tempo_segundos
    );
  }),

  criarOuAtualizarSessao: handleRequest(async (req) => {
    return analyticsService.criarOuAtualizarSessao({
      sessao_id: req.body.sessao_id,
      usuario_id: req.user?.id || null,
      ip_address: req.ip || req.connection.remoteAddress,
      user_agent: req.get('user-agent'),
      dispositivo_tipo: req.body.dispositivo_tipo || null,
      navegador: req.body.navegador || null,
      sistema_operacional: req.body.sistema_operacional || null,
    });
  }),

  finalizarSessao: handleRequest(async (req) => {
    return analyticsService.finalizarSessao(
      req.body.sessao_id,
      req.body.duracao_segundos
    );
  }),

  getEstatisticasGerais: handleRequest(async (req) => {
    const dataInicio = req.query.data_inicio || null;
    const dataFim = req.query.data_fim || null;
    return analyticsService.getEstatisticasGerais(dataInicio, dataFim);
  }),

  getPageViewsStats: handleRequest(async (req) => {
    const dataInicio = req.query.data_inicio || null;
    const dataFim = req.query.data_fim || null;
    return analyticsService.getPageViewsStats(dataInicio, dataFim);
  }),

  getEventosPorTipo: handleRequest(async (req) => {
    const dataInicio = req.query.data_inicio || null;
    const dataFim = req.query.data_fim || null;
    return analyticsService.getEventosPorTipo(dataInicio, dataFim);
  }),

  getSessoesStats: handleRequest(async (req) => {
    const dataInicio = req.query.data_inicio || null;
    const dataFim = req.query.data_fim || null;
    return analyticsService.getSessoesStats(dataInicio, dataFim);
  }),

  getAtividadePorHora: handleRequest(async (req) => {
    const dataInicio = req.query.data_inicio || null;
    const dataFim = req.query.data_fim || null;
    return analyticsService.getAtividadePorHora(dataInicio, dataFim);
  }),

  getCrescimentoUsuarios: handleRequest(async (req) => {
    const dataInicio = req.query.data_inicio || null;
    const dataFim = req.query.data_fim || null;
    return analyticsService.getCrescimentoUsuarios(dataInicio, dataFim);
  }),

  getFunilPermuta: handleRequest(async () => analyticsService.getFunilPermuta()),

  getDemandaPorMunicipio: handleRequest(async (req) => {
    return analyticsService.getDemandaPorMunicipio({
      forca_id: req.query.forca_id ? parseInt(req.query.forca_id, 10) : null,
      estado_id: req.query.estado_id ? parseInt(req.query.estado_id, 10) : null,
      limit: req.query.limit ? parseInt(req.query.limit, 10) : 50,
    });
  }),

  getDemandaPorForca: handleRequest(async () => analyticsService.getDemandaPorForca()),

  getEngajamentoPermuta: handleRequest(async (req) => {
    return analyticsService.getEngajamentoPermuta(
      req.query.data_inicio || null,
      req.query.data_fim || null
    );
  }),

  getHistoricoIntencoes: handleRequest(async (req) => {
    return analyticsService.getHistoricoIntencoes({
      limit: req.query.limit ? parseInt(req.query.limit, 10) : 20,
    });
  }),
};

