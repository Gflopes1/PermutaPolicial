const { Joi } = require('celebrate');

module.exports = {
  paramsId: Joi.object({
    id: Joi.number().integer().required(),
  }),

  registerClick: Joi.object({
    tipo: Joi.string().valid('contato', 'site').required(),
  }),

  upsertAdvogado: Joi.object({
    nome: Joi.string().required().min(2).max(255),
    descricao_curta: Joi.string().required().min(5).max(500),
    descricao_detalhada: Joi.string().allow('').max(10000).optional(),
    site_url: Joi.string().allow('').max(1024).optional(),
    contato_whatsapp: Joi.string().allow('').max(30).optional(),
    contato_telefone: Joi.string().allow('').max(30).optional(),
    contato_email: Joi.string().allow('').email().optional(),
    ordem: Joi.number().integer().min(0).optional(),
    ativo: Joi.boolean().optional(),
  }),
};
