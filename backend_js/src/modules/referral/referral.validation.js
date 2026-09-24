const { Joi, Segments } = require('celebrate');

module.exports = {
  validateCode: {
    [Segments.PARAMS]: Joi.object({
      code: Joi.string().trim().min(3).max(12).required(),
    }),
  },

  registerClick: {
    [Segments.BODY]: Joi.object({
      code: Joi.string().trim().min(3).max(12).required(),
    }),
  },

  ranking: {
    [Segments.QUERY]: Joi.object({
      scope: Joi.string().valid('geral', 'forca', 'estado').default('forca'),
      forca_id: Joi.number().integer().optional(),
      estado_id: Joi.number().integer().optional(),
      page: Joi.number().integer().min(1).default(1),
      limit: Joi.number().integer().min(1).max(100).default(20),
    }),
  },

  dismissCampaign: {
    [Segments.BODY]: Joi.object({
      campaign_id: Joi.string().trim().max(64).required(),
    }),
  },

  attachReferral: {
    [Segments.BODY]: Joi.object({
      referral_code: Joi.string().trim().min(3).max(12).required(),
    }),
  },

  adminRanking: {
    [Segments.QUERY]: Joi.object({
      scope: Joi.string().valid('geral', 'forca', 'estado').default('geral'),
      forca_id: Joi.number().integer().optional(),
      estado_id: Joi.number().integer().optional(),
      limit: Joi.number().integer().min(1).max(100).default(50),
      offset: Joi.number().integer().min(0).default(0),
    }),
  },

  adminUserId: {
    [Segments.PARAMS]: Joi.object({
      id: Joi.number().integer().required(),
    }),
  },

  updateForceGoal: {
    [Segments.PARAMS]: Joi.object({
      forcaId: Joi.number().integer().required(),
    }),
    [Segments.BODY]: Joi.object({
      meta_usuarios: Joi.number().integer().min(1).required(),
      ativo: Joi.boolean().default(true),
    }),
  },

  adminCampaign: {
    [Segments.BODY]: Joi.object({
      id: Joi.string().trim().min(3).max(64).required(),
      title: Joi.string().trim().min(3).max(200).required(),
      description: Joi.string().trim().min(3).max(5000).required(),
      primary_action: Joi.string().valid('referral', 'close').default('referral'),
      primary_label: Joi.string().trim().max(80).optional().allow('', null),
      secondary_label: Joi.string().trim().max(80).optional().allow('', null),
      show_share: Joi.boolean().default(true),
      active: Joi.boolean().default(true),
    }),
  },
};
