// /src/modules/chat/chat.validation.js

const { celebrate, Joi } = require('celebrate');

module.exports = {
  createMensagem: celebrate({
    body: Joi.object({
      mensagem: Joi.string().required().min(1).max(5000),
    }),
  }),

  iniciarConversa: celebrate({
    body: Joi.object({
      usuarioId: Joi.number().integer().required(),
    }),
  }),
};


