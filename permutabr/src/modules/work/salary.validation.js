// /src/modules/work/salary.validation.js

const { Joi, Segments } = require('celebrate');

module.exports = {
  // PUT /api/salary/settings
  updateSettings: {
    [Segments.BODY]: Joi.object().keys({
      carga_horaria_dia: Joi.number().min(0).max(24).optional(),
      valor_hora_extra: Joi.number().min(0).optional(),
      vale_alimentacao: Joi.number().min(0).optional(),
      dia_pagamento_va: Joi.number().integer().min(1).max(31).optional(),
      etapa_value: Joi.number().min(0).optional(),
      previdencia_aliquota: Joi.number().min(0).max(1).optional(),
      etapa_rule: Joi.string().optional(),
      abatimento_horas: Joi.number().min(0).max(24).optional(),
      salario_base: Joi.number().min(0).optional(),
      desconto_consignados: Joi.number().min(0).allow(null).optional(),
      outros_descontos: Joi.number().min(0).allow(null).optional(),
      outras_vantagens: Joi.number().min(0).allow(null).optional(),
    }).unknown(true), // Permite campos adicionais para flexibilidade
  },

  // GET /api/salary/preview
  previewMonth: {
    [Segments.QUERY]: Joi.object().keys({
      month: Joi.number().integer().min(1).max(12).required(),
      year: Joi.number().integer().min(2020).max(2100).required(),
    }),
  },

  // POST /api/salary/generate
  generateMonth: {
    [Segments.QUERY]: Joi.object().keys({
      month: Joi.number().integer().min(1).max(12).required(),
      year: Joi.number().integer().min(2020).max(2100).required(),
    }),
  },

  // GET /api/salary/export
  exportMonth: {
    [Segments.QUERY]: Joi.object().keys({
      month: Joi.number().integer().min(1).max(12).required(),
      year: Joi.number().integer().min(2020).max(2100).required(),
      format: Joi.string().valid('pdf').default('pdf'),
    }),
  },
};


