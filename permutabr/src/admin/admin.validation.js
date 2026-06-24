// /src/modules/admin/admin.validation.js

const { Joi, Segments } = require('celebrate');

// Um esquema reutilizável para qualquer rota que processe um ID numérico
const processByIdSchema = {
  [Segments.PARAMS]: Joi.object().keys({
    id: Joi.number().integer().required(),
  }),
};

module.exports = {
  processaSugestao: processByIdSchema,
  processaVerificacao: processByIdSchema,
  getPolicialDetalhes: processByIdSchema,
  deletePolicial: processByIdSchema,
  sendBulkEmail: {
    [Segments.BODY]: Joi.object().keys({
      subject: Joi.string().required().min(3).max(200),
      body: Joi.string().required().min(10).max(10000),
    }),
  },
  getAllPoliciais: {
    [Segments.QUERY]: Joi.object().keys({
      search: Joi.string().max(200).allow(''),
      status_verificacao: Joi.string().max(50),
      forca_id: Joi.number().integer(),
      limit: Joi.number().integer().min(1).max(100).default(20),
      offset: Joi.number().integer().min(0).default(0),
    }),
  },
  updatePolicial: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required(),
    }),
    [Segments.BODY]: Joi.object().keys({
      nome: Joi.string().max(255),
      email: Joi.string().email().max(255),
      id_funcional: Joi.string().max(100).allow('', null),
      qso: Joi.string().max(255).allow('', null),
      status_verificacao: Joi.string().valid('VERIFICADO', 'REJEITADO', 'AGUARDANDO_VERIFICACAO_EMAIL', 'NAO_VERIFICADO'),
      is_moderator: Joi.number().valid(0, 1),
      embaixador: Joi.number().valid(0, 1),
      is_premium: Joi.number().valid(0, 1),
      forca_id: Joi.number().integer(),
      unidade_atual_id: Joi.number().integer().allow(null),
      destaque_dias: Joi.number().integer().min(0).max(365).allow(null),
      destaque_ate: Joi.string().isoDate().allow(null),
      alertas_match_ativo: Joi.number().valid(0, 1),
    }).min(1),
  },
  atualizarProblemaRelatoStatus: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required(),
    }),
    [Segments.BODY]: Joi.object().keys({
      status: Joi.string().valid('PENDENTE', 'EM_ANALISE', 'RESOLVIDO', 'DESCARTADO').required(),
      resolucao: Joi.string().max(5000).allow(null, ''),
    }),
  },
};