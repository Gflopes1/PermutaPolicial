const { Joi, Segments } = require('celebrate');

module.exports = {
  submitOcr: {
    [Segments.BODY]: Joi.object().keys({
      tipo_documento: Joi.string().valid('funcional', 'contracheque').required(),
      nome_extraido: Joi.string().max(255).allow('', null),
      matricula_extraida: Joi.string().max(500).allow('', null),
      forca_extraida: Joi.string().max(100).allow('', null),
      cargo_extraido: Joi.string().max(100).allow('', null),
      ocr_raw_text: Joi.string().max(50000).allow('', null),
    }),
  },
  processOcrReview: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().positive().required(),
    }),
  },
};
