// /src/modules/chat/chat.validation.js

const { Joi, Segments } = require('celebrate');

module.exports = {
  createMensagem: {
    [Segments.BODY]: Joi.object().keys({
      mensagem: Joi.string().required().min(1).max(5000),
    }),
  },

  iniciarConversa: {
    [Segments.BODY]: Joi.object().keys({
      usuarioId: Joi.number().integer().required(),
      anonima: Joi.boolean().optional().default(false),
    }),
  },
};




