// /src/modules/permutas/permutas.validation.js

const { Joi, Segments } = require('celebrate');

module.exports = {
    // GET /api/permutas/matches
    findMatches: {
        [Segments.QUERY]: Joi.object().keys({}),
    },

    // POST /api/permutas/preview-simulacao (público)
    previewSimulacao: {
        [Segments.BODY]: Joi.object().keys({
            forca_id: Joi.number().integer().optional(),
            tipo_permuta: Joi.string().max(10).optional(),
            cidade_atual: Joi.string().max(120).optional(),
            cidade_destino: Joi.string().max(120).optional(),
            municipio_atual_id: Joi.number().integer().optional(),
            municipio_destino_id: Joi.number().integer().optional(),
            estado: Joi.string().length(2).uppercase().optional(),
            estado_destino: Joi.string().length(2).uppercase().optional(),
            raio_km: Joi.number().integer().min(10).max(500).optional(),
        }).or('cidade_atual', 'municipio_atual_id')
          .or('cidade_destino', 'municipio_destino_id')
          .or('forca_id', 'tipo_permuta'),
    },
};