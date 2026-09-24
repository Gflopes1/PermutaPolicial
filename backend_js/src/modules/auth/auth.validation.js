// /src/modules/auth/auth.validation.js

const { Joi, Segments } = require('celebrate');

// Mínimo 8 caracteres. Complexidade (maiúscula/número/especial) é recomendação no frontend, não bloqueio.
const passwordSchema = Joi.string()
  .min(8)
  .required()
  .messages({
    'string.min': 'A senha deve ter no mínimo 8 caracteres.',
    'any.required': 'Senha é obrigatória.',
    'string.empty': 'Senha é obrigatória.',
  });

module.exports = {
  // POST /api/auth/registrar
  registrar: {
    [Segments.BODY]: Joi.object().keys({
      nome: Joi.string().required(),
      id_funcional: Joi.string().required(),
      forca_id: Joi.number().integer().required(),
      email: Joi.string().email({ tlds: { allow: false } }).required(),
      qso: Joi.string().required(),
      senha: passwordSchema,
      referral_code: Joi.string().trim().min(3).max(12).optional().allow(null, ''),
    }),
  },

  // POST /api/auth/login
  login: {
    [Segments.BODY]: Joi.object().keys({
      email: Joi.string().email({ tlds: { allow: false } }).required(),
      senha: Joi.string().required(),
    }),
  },

  // POST /api/auth/confirmar-email
  confirmarEmail: {
    [Segments.BODY]: Joi.object().keys({
      email: Joi.string().email({ tlds: { allow: false } }).required(),
      codigo: Joi.string().length(6).required(),
      referral_code: Joi.string().trim().min(3).max(12).optional().allow(null, ''),
    }),
  },
  
  // POST /api/auth/solicitar-recuperacao
  solicitarRecuperacao: {
      [Segments.BODY]: Joi.object().keys({
          email: Joi.string().email({ tlds: { allow: false } }).required(),
      }),
  },

  // POST /api/auth/validar-codigo
  validarCodigo: {
      [Segments.BODY]: Joi.object().keys({
          email: Joi.string().email({ tlds: { allow: false } }).required(),
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

  // POST /api/auth/google/native — Google Sign-In no APK
  googleNative: {
    [Segments.BODY]: Joi.object().keys({
      id_token: Joi.string().required(),
      referral_code: Joi.string().trim().min(3).max(12).optional().allow(null, ''),
    }),
  },

  // POST /api/auth/exchange-code — troca código OAuth de uso único por JWT
  exchangeCode: {
    [Segments.BODY]: Joi.object().keys({
      code: Joi.string().hex().length(64).required(),
    }),
  },
};