// /src/modules/mapa-tatico/mapa-tatico.validation.js

const { Joi } = require('celebrate');

const OPERATIONAL_TYPES = ['ocorrencia_recente', 'suspeito', 'local_interesse'];
const LOGISTICS_TYPES = ['restaurante', 'padaria', 'base'];
const ALL_TYPES = [...OPERATIONAL_TYPES, ...LOGISTICS_TYPES];

const pointTypeValidator = Joi.string().valid(...ALL_TYPES).required();
const mapTypeValidator = Joi.string().valid('OPERATIONAL', 'LOGISTICS').required();

module.exports = {
  createGroup: Joi.object({
    name: Joi.string().required().min(2).max(255),
  }),

  inviteGroup: Joi.object({
    email: Joi.string().email().required(),
  }),

  nomeDeGuerra: Joi.object({
    nome_de_guerra: Joi.string().allow('').max(100).optional(),
  }),

  muteMember: Joi.object({
    is_muted: Joi.boolean().required(),
  }),

  createPoint: Joi.object({
    group_id: Joi.number().integer().required(),
    title: Joi.string().required().min(1).max(255),
    address: Joi.string().allow('').max(500).optional(),
    lat: Joi.number().required(),
    lng: Joi.number().required(),
    type: pointTypeValidator,
    map_type: mapTypeValidator,
    expires_at: Joi.date().iso().allow(null).optional(),
  }),

  updatePoint: Joi.object({
    title: Joi.string().min(1).max(255).optional(),
    address: Joi.string().allow('').max(500).optional(),
    lat: Joi.number().optional(),
    lng: Joi.number().optional(),
    type: pointTypeValidator.optional(),
    map_type: mapTypeValidator.optional(),
    expires_at: Joi.date().iso().allow(null).optional(),
  }),

  createComment: Joi.object({
    text: Joi.string().required().min(1).max(2000),
  }),

  reportPoint: Joi.object({
    reason: Joi.string().allow('').max(500).optional(),
  }),

  paramsGroupId: Joi.object({
    id: Joi.number().integer().required(),
  }),

  paramsInviteId: Joi.object({
    inviteId: Joi.number().integer().required(),
  }),

  paramsGroupIdUserId: Joi.object({
    groupId: Joi.number().integer().required(),
    userId: Joi.number().integer().required(),
  }),

  paramsPointId: Joi.object({
    id: Joi.number().integer().required(),
  }),

  queryLastDays: Joi.object({
    lastDays: Joi.number().integer().min(1).max(30).optional(),
  }),
};
