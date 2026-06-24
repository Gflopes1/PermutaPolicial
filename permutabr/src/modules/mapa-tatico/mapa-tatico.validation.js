// /src/modules/mapa-tatico/mapa-tatico.validation.js

const { Joi } = require('celebrate');

const {
  OPERATIONAL_TYPES,
  LOGISTICS_TYPES,
  SHARED_TYPES,
  NATIONAL_TYPES,
  ALL_TYPES,
  MAP_TYPES,
} = require('./mapa-tatico.types');

const pointTypeValidator = Joi.string().valid(...ALL_TYPES).required();
const mapTypeValidator = Joi.string().valid(...MAP_TYPES).required();

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
    description: Joi.string().allow('').max(5000).optional(),
    lat: Joi.number().required(),
    lng: Joi.number().required(),
    type: pointTypeValidator,
    map_type: mapTypeValidator,
    expires_at: Joi.date().iso().allow(null).optional(),
  }),

  updatePoint: Joi.object({
    title: Joi.string().min(1).max(255).optional(),
    address: Joi.string().allow('').max(500).optional(),
    description: Joi.string().allow('').max(5000).optional(),
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

  paramsReportId: Joi.object({
    reportId: Joi.number().integer().required(),
  }),

  queryLastDays: Joi.object({
    lastDays: Joi.number().integer().min(1).max(30).optional(),
    limit: Joi.number().integer().min(1).max(100).optional(),
    offset: Joi.number().integer().min(0).optional(),
  }),

  queryPoints: Joi.object({
    group_id: Joi.number().integer().required(),
    map_type: Joi.string().valid(...MAP_TYPES, 'ALL').required(),
    since: Joi.date().iso().optional(),
  }),

  queryGeocodeSearch: Joi.object({
    q: Joi.string().min(3).max(500).required(),
  }),

  queryGeocodeReverse: Joi.object({
    lat: Joi.number().required(),
    lng: Joi.number().required(),
  }),

  updateMemberLocation: Joi.object({
    lat: Joi.number().required(),
    lng: Joi.number().required(),
    sharing_enabled: Joi.boolean().optional(),
  }),

  queryIntelligence: Joi.object({
    map_type: Joi.string().valid(...MAP_TYPES).required(),
    days: Joi.number().integer().min(1).max(90).optional(),
  }),

  OPERATIONAL_TYPES,
  LOGISTICS_TYPES,
  SHARED_TYPES,
  NATIONAL_TYPES,

  reviewReport: Joi.object({
    status: Joi.string().valid('REVIEWED', 'DISMISSED').required(),
    admin_notes: Joi.string().allow('').max(2000).optional(),
  }),

  queryPagination: Joi.object({
    limit: Joi.number().integer().min(1).max(100).optional(),
    offset: Joi.number().integer().min(0).optional(),
  }),
};
