// /src/modules/intencoes/intencoes.validation.js

const { Joi, Segments } = require('celebrate');

module.exports = {
  // PUT /api/intencoes/me
  updateMyIntentions: {
    [Segments.BODY]: Joi.object({
      intencoes: Joi.array().items(
        Joi.object({
          prioridade: Joi.number().integer().required(),
          tipo_intencao: Joi.string().valid('ESTADO', 'MUNICIPIO', 'UNIDADE').required(),
          estado_id: Joi.number().integer().allow(null).optional(),
          municipio_id: Joi.number().integer().allow(null).optional(),
          unidade_id: Joi.number().integer().allow(null).optional(),
        })
      ).required(),
    }),
  },
};