// /src/modules/work/presets.validation.js

const { Joi, Segments } = require('celebrate');

module.exports = {
  // POST /api/presets
  createPreset: {
    [Segments.BODY]: Joi.object().keys({
      nome: Joi.string().required().min(1).max(255),
      cor: Joi.string().required().pattern(/^#[0-9A-Fa-f]{6}$/),
      duracao: Joi.number().min(0).max(24).optional(),
      tipo: Joi.string().valid('normal', 'plantao', 'folga', 'atestado', 'abatimento', 'ferias').optional(),
      flag_abatimento: Joi.boolean().optional(),
      etapa_rule_override: Joi.string().allow('', null).optional(),
      visibilidade: Joi.string().valid('private', 'public').optional(),
      intervals: Joi.array().items(
        Joi.object().keys({
          start_time: Joi.string().pattern(/^([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$/).required(),
          end_time: Joi.string().pattern(/^([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$/).required(),
        })
      ).optional(),
    }),
  },

  // PUT /api/presets/:id
  updatePreset: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required(),
    }),
    [Segments.BODY]: Joi.object().keys({
      nome: Joi.string().min(1).max(255).optional(),
      cor: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/).optional(),
      duracao: Joi.number().min(0).max(24).optional(),
      tipo: Joi.string().valid('normal', 'plantao', 'folga', 'atestado', 'abatimento', 'ferias').optional(),
      flag_abatimento: Joi.boolean().optional(),
      etapa_rule_override: Joi.string().allow('', null).optional(),
      visibilidade: Joi.string().valid('private', 'public').optional(),
      intervals: Joi.array().items(
        Joi.object().keys({
          start_time: Joi.string().pattern(/^([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$/).required(),
          end_time: Joi.string().pattern(/^([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$/).required(),
        })
      ).optional(),
    }),
  },

  // DELETE /api/presets/:id
  deletePreset: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required(),
    }),
  },
};


