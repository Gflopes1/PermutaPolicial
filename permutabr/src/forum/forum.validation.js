// /src/modules/forum/forum.validation.js

const { Joi } = require('celebrate');

module.exports = {
  createTopico: Joi.object({
    categoria_id: Joi.number().integer().required(),
    titulo: Joi.string().required().min(3).max(255),
    conteudo: Joi.string().required().min(10).max(10000),
  }),

  updateTopico: Joi.object({
    titulo: Joi.string().min(3).max(255).optional(),
    conteudo: Joi.string().min(10).max(10000).optional(),
  }),

  createResposta: Joi.object({
    conteudo: Joi.string().required().min(1).max(5000),
    resposta_id: Joi.number().integer().optional(),
  }),

  updateResposta: Joi.object({
    conteudo: Joi.string().required().min(1).max(5000),
  }),

  toggleReacao: {
    body: Joi.object({
      tipo: Joi.string().valid('curtida', 'descurtida').default('curtida'),
    }),
    query: Joi.object({
      topicoId: Joi.number().integer().optional(),
      respostaId: Joi.number().integer().optional(),
    }).or('topicoId', 'respostaId'),
  },

  // Moderação
  aprovarTopico: {
    params: Joi.object({
      topicoId: Joi.number().integer().required(),
    }),
  },

  rejeitarTopico: {
    params: Joi.object({
      topicoId: Joi.number().integer().required(),
    }),
    body: Joi.object({
      motivo_rejeicao: Joi.string().required().min(5).max(500),
    }),
  },

  aprovarResposta: {
    params: Joi.object({
      respostaId: Joi.number().integer().required(),
    }),
  },

  rejeitarResposta: {
    params: Joi.object({
      respostaId: Joi.number().integer().required(),
    }),
    body: Joi.object({
      motivo_rejeicao: Joi.string().required().min(5).max(500),
    }),
  },

  toggleFixarTopico: {
    params: Joi.object({
      topicoId: Joi.number().integer().required(),
    }),
  },

  toggleBloquearTopico: {
    params: Joi.object({
      topicoId: Joi.number().integer().required(),
    }),
  },
};