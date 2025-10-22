// /src/modules/mapa/mapa.validation.js

const { Joi, Segments } = require('celebrate');

module.exports = {
  // GET /api/mapa/dados
  getMapData: {
    [Segments.QUERY]: Joi.object().keys({
      estado_id: Joi.number().integer().optional(),
      forca_id: Joi.number().integer().optional(),
      tipo: Joi.string().valid('saindo', 'vindo', 'balanco').default('saindo'),
    }),
  },
  
  // GET /api/mapa/detalhes-municipio
  getMunicipioDetails: {
    [Segments.QUERY]: Joi.object().keys({
      id: Joi.number().integer().required(),
      tipo: Joi.string().valid('saindo', 'vindo').required(),
      estado_id: Joi.number().integer().optional(),
      forca_id: Joi.number().integer().optional(),
    }),
  },
};