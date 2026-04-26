// /src/modules/problemas/problemas.validation.js

const { Joi } = require('celebrate');

module.exports = {
  criarRelato: {
    body: Joi.object({
      pagina: Joi.string().required().max(255),
      detalhes: Joi.string().required().min(10).max(5000),
    }),
  },

  buscarRelatos: {
    query: Joi.object({
      status: Joi.string().valid('PENDENTE', 'EM_ANALISE', 'RESOLVIDO', 'DESCARTADO'),
      pagina: Joi.string().max(255),
      usuario_id: Joi.number().integer().positive(),
      data_inicio: Joi.date().iso(),
      data_fim: Joi.date().iso(),
      page: Joi.number().integer().min(1).default(1),
      per_page: Joi.number().integer().min(1).max(100).default(20),
    }),
  },

  atualizarStatus: {
    params: Joi.object({
      id: Joi.number().integer().positive().required(),
    }),
    body: Joi.object({
      status: Joi.string().valid('PENDENTE', 'EM_ANALISE', 'RESOLVIDO', 'DESCARTADO').required(),
      resolucao: Joi.string().max(5000).allow(null, ''),
    }),
  },

  buscarRelatoPorId: {
    params: Joi.object({
      id: Joi.number().integer().positive().required(),
    }),
  },

  getEstatisticas: {
    query: Joi.object({
      data_inicio: Joi.date().iso(),
      data_fim: Joi.date().iso(),
    }),
  },
};
