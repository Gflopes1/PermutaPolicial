// /src/modules/auth/auth.validation.js

const { Joi, Segments } = require('celebrate');

// Requisitos para uma senha forte
const passwordSchema = Joi.string()
  .min(8)
  .pattern(new RegExp('[A-Z]'))
  .pattern(new RegExp('[!@#$%^&*(),.?":{}|<>]'))
  .required()
  .messages({
    'string.min': 'A senha deve ter no mínimo 8 caracteres.',
    'string.pattern.base': 'A senha deve conter pelo menos uma letra maiúscula e um caractere especial.',
    'any.required': 'Senha é obrigatória.'
  });

module.exports = {
  // POST /api/auth/registrar
  registrar: {
    [Segments.BODY]: Joi.object().keys({
      nome: Joi.string().required(),
      id_funcional: Joi.string().required(),
      forca_id: Joi.number().integer().required(),
      email: Joi.string().email().required(),
      qso: Joi.string().required(),
      senha: passwordSchema,
    }),
  },

  // POST /api/auth/login
  login: {
    [Segments.BODY]: Joi.object().keys({
      email: Joi.string().email().required(),
      senha: Joi.string().required(),
    }),
  },

  // POST /api/auth/confirmar-email
  confirmarEmail: {
    [Segments.BODY]: Joi.object().keys({
      email: Joi.string().email().required(),
      codigo: Joi.string().length(6).required(),
    }),
  },
  
  // POST /api/auth/solicitar-recuperacao
  solicitarRecuperacao: {
      [Segments.BODY]: Joi.object().keys({
          email: Joi.string().email().required(),
      }),
  },

  // POST /api/auth/validar-codigo
  validarCodigo: {
      [Segments.BODY]: Joi.object().keys({
          email: Joi.string().email().required(),
          codigo: Joi.string().length(6).required(),
      }),
  },

  // POST /api/auth/redefinir-senha
  redefinirSenha: {
      [Segments.BODY]: Joi.object().keys({
          token_recuperacao: Joi.string().required(),
          nova_senha: passwordSchema,
      }),
  },
};