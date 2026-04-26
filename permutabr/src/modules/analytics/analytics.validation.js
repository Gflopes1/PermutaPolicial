// /src/modules/analytics/analytics.validation.js

const { Joi, Segments } = require('celebrate');

module.exports = {
  registrarEvento: {
    [Segments.BODY]: Joi.object().keys({
      evento_tipo: Joi.string().required(),
      metadata: Joi.object().allow(null).optional(),
    }),
  },

  registrarPageView: {
    [Segments.BODY]: Joi.object().keys({
      pagina: Joi.string().required(),
      sessao_id: Joi.string().required(),
    }),
  },

  atualizarTempoPermanencia: {
    [Segments.BODY]: Joi.object().keys({
      page_view_id: Joi.number().integer().required(),
      tempo_segundos: Joi.number().integer().required(),
    }),
  },

  criarOuAtualizarSessao: {
    [Segments.BODY]: Joi.object().keys({
      sessao_id: Joi.string().required(),
      dispositivo_tipo: Joi.string().valid('desktop', 'mobile', 'tablet').allow('', null).optional(),
      navegador: Joi.string().allow('', null).optional(),
      sistema_operacional: Joi.string().allow('', null).optional(),
      ip_address: Joi.string().allow('', null).optional(),
      user_agent: Joi.string().allow('', null).optional(),
      usuario_id: Joi.number().integer().allow(null).optional(),
    }).unknown(true), // Permite campos adicionais para flexibilidade
  },

  finalizarSessao: {
    [Segments.BODY]: Joi.object().keys({
      sessao_id: Joi.string().required(),
      duracao_segundos: Joi.number().integer().required(),
    }),
  },

  getEstatisticasGerais: {
    [Segments.QUERY]: Joi.object().keys({
      data_inicio: Joi.string().optional(),
      data_fim: Joi.string().optional(),
    }),
  },

  getPageViewsStats: {
    [Segments.QUERY]: Joi.object().keys({
      data_inicio: Joi.string().optional(),
      data_fim: Joi.string().optional(),
    }),
  },

  getEventosPorTipo: {
    [Segments.QUERY]: Joi.object().keys({
      data_inicio: Joi.string().optional(),
      data_fim: Joi.string().optional(),
    }),
  },

  getSessoesStats: {
    [Segments.QUERY]: Joi.object().keys({
      data_inicio: Joi.string().optional(),
      data_fim: Joi.string().optional(),
    }),
  },

  getAtividadePorHora: {
    [Segments.QUERY]: Joi.object().keys({
      data_inicio: Joi.string().optional(),
      data_fim: Joi.string().optional(),
    }),
  },

  getCrescimentoUsuarios: {
    [Segments.QUERY]: Joi.object().keys({
      data_inicio: Joi.string().optional(),
      data_fim: Joi.string().optional(),
    }),
  },
};

