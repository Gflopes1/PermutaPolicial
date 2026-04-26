// /src/modules/work/work.validation.js

const { Joi, Segments } = require('celebrate');

module.exports = {
  // GET /api/work/month
  getMonth: {
    [Segments.QUERY]: Joi.object().keys({
      month: Joi.number().integer().min(1).max(12).required(),
      year: Joi.number().integer().min(2020).max(2100).required(),
    }),
  },

  // POST /api/work/day
  upsertDay: {
    [Segments.BODY]: Joi.object().keys({
      data: Joi.string().isoDate().required(),
      preset_id: Joi.number().integer().allow(null).optional(),
      total_hours: Joi.number().min(0).max(24).optional(),
      etapas: Joi.number().integer().min(0).optional(),
      tipo: Joi.string().valid('normal', 'plantao', 'folga', 'atestado', 'abatimento', 'ferias').optional(),
      flag_abatimento: Joi.boolean().optional(),
      observacoes: Joi.string().allow('', null).optional(),
      intervals: Joi.array().items(
        Joi.object().keys({
          start_time: Joi.string().isoDate().required(),
          end_time: Joi.string().isoDate().required(),
        })
      ).optional(),
    }),
  },

  // DELETE /api/work/day/:id
  deleteDay: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required(),
    }),
  },

  // POST /api/work/apply-preset
  applyPreset: {
    [Segments.BODY]: Joi.object().keys({
      dates: Joi.array().items(Joi.string().isoDate()).min(1).required(),
      preset_id: Joi.number().integer().required(),
    }),
  },
};


