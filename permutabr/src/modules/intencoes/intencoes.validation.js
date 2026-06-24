// /src/modules/intencoes/intencoes.validation.js

const { Joi, Segments } = require('celebrate');

const intencaoItemSchema = Joi.object({
  prioridade: Joi.number().integer().min(1).max(3).required(),
  tipo_intencao: Joi.string().valid('ESTADO', 'MUNICIPIO', 'UNIDADE').required(),
  estado_id: Joi.number().integer().allow(null).optional(),
  municipio_id: Joi.number().integer().allow(null).optional(),
  unidade_id: Joi.number().integer().allow(null).optional(),
  raio_km: Joi.number().integer().min(10).max(500).allow(null).optional(),
}).custom((value, helpers) => {
  if (value.tipo_intencao === 'ESTADO' && !value.estado_id) {
    return helpers.error('any.custom', { message: 'estado_id é obrigatório para intenção ESTADO' });
  }
  if (value.tipo_intencao === 'MUNICIPIO' && !value.municipio_id) {
    return helpers.error('any.custom', { message: 'municipio_id é obrigatório para intenção MUNICIPIO' });
  }
  if (value.tipo_intencao === 'UNIDADE' && !value.unidade_id) {
    return helpers.error('any.custom', { message: 'unidade_id é obrigatório para intenção UNIDADE' });
  }
  if (value.raio_km != null && value.tipo_intencao === 'ESTADO') {
    return helpers.error('any.custom', { message: 'raio_km só se aplica a intenções MUNICIPIO ou UNIDADE' });
  }
  return value;
});

module.exports = {
  updateMyIntentions: {
    [Segments.BODY]: Joi.object({
      intencoes: Joi.array()
        .items(intencaoItemSchema)
        .max(3)
        .required()
        .custom((value, helpers) => {
          const prioridades = value.map((i) => i.prioridade);
          if (new Set(prioridades).size !== prioridades.length) {
            return helpers.error('any.custom', { message: 'Prioridades devem ser únicas (1, 2 e 3)' });
          }
          return value;
        }),
    }),
  },
};
