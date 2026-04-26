// /src/modules/notificacoes/notificacoes.validation.js

const { Joi, Segments } = require('celebrate');

module.exports = {
  criarSolicitacaoContato: {
    [Segments.BODY]: Joi.object().keys({
      destinatario_id: Joi.number().integer().required(),
      origem: Joi.string().valid('mapa', 'permuta').optional(),
      tipo_permuta: Joi.string().optional(), // 'direta', 'triangular', 'interessado'
    }),
  },

  responderSolicitacaoContato: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required(),
    }),
    [Segments.BODY]: Joi.object().keys({
      aceitar: Joi.boolean().required(),
    }),
  },
};

