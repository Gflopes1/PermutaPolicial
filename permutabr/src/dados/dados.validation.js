// /src/modules/dados/dados.validation.js

const { Joi, Segments } = require('celebrate');

module.exports = {
  // GET /api/dados/municipios/:estado_id
  getMunicipiosPorEstado: {
    [Segments.PARAMS]: Joi.object().keys({
      estado_id: Joi.number().integer().required(),
    }),
  },

  // GET /api/dados/unidades?municipio_id=X&forca_id=Y
  getUnidades: {
    [Segments.QUERY]: Joi.object().keys({
      municipio_id: Joi.number().integer().required(),
      forca_id: Joi.number().integer().required(),
    }),
  },

  // POST /api/dados/unidades/sugerir
  sugerirUnidade: {
    [Segments.BODY]: Joi.object().keys({
      nome_sugerido: Joi.string().required(),
      municipio_id: Joi.number().integer().required(),
      forca_id: Joi.number().integer().required(),
    }),
  },

  // GET /api/dados/postos/:tipo_permuta
  getPostosPorForca: {
    [Segments.PARAMS]: Joi.object().keys({
      tipo_permuta: Joi.string().required(),
    }),
  },
};