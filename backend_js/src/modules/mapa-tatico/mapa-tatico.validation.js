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
    visibility: Joi.string().valid('GROUP', 'PRIVATE').default('GROUP').optional(),
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
    visibility: Joi.string().valid('GROUP', 'PRIVATE').optional(),
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

  createOccurrenceLog: Joi.object({
    narrative: Joi.string().required().min(5).max(5000),
    entry_type: Joi.string().valid('ATUALIZACAO', 'MUDANCA_STATUS', 'EVIDENCIA', 'OBSERVACAO').optional(),
    status: Joi.string().valid('EM_ANDAMENTO', 'CONCLUIDA', 'ARQUIVADA').allow(null).optional(),
    occurred_at: Joi.date().iso().optional(),
  }),

  upsertSuspectProfile: Joi.object({
    apelido: Joi.string().allow('', null).max(100).optional(),
    caracteristicas_fisicas: Joi.string().allow('', null).max(5000).optional(),
    altura_cm: Joi.number().integer().min(50).max(280).allow(null).optional(),
    compleicao: Joi.string().valid('MAGRA', 'MEDIA', 'FORTE').allow(null).optional(),
    tatuagens_marcas: Joi.string().allow('', null).max(5000).optional(),
    veiculos_associados: Joi.string().allow('', null).max(5000).optional(),
    modus_operandi: Joi.string().allow('', null).max(5000).optional(),
    nivel_periculosidade: Joi.string().valid('BAIXO', 'MEDIO', 'ALTO', 'ARMADO').optional(),
    orientacoes_abordagem: Joi.string().allow('', null).max(5000).optional(),
    bo_rai_numero: Joi.string().allow('', null).max(50).optional(),
    fundamentacao: Joi.string().required().min(20).max(5000),
  }),

  paramsPhotoId: Joi.object({
    id: Joi.number().integer().required(),
    photoId: Joi.number().integer().required(),
  }),

  queryAdminGroups: Joi.object({
    page: Joi.number().integer().min(1).optional(),
    limit: Joi.number().integer().min(1).max(100).optional(),
    search: Joi.string().allow('').max(255).optional(),
  }),

  queryAdminGroupDetail: Joi.object({
    map_type: Joi.string().valid(...MAP_TYPES).optional(),
    type: Joi.string().max(50).optional(),
    limit: Joi.number().integer().min(1).max(100).optional(),
    offset: Joi.number().integer().min(0).optional(),
  }),

  paramsAdminGroupPoint: Joi.object({
    id: Joi.number().integer().required(),
    pointId: Joi.number().integer().required(),
  }),

  paramsAdminGroupMember: Joi.object({
    id: Joi.number().integer().required(),
    userId: Joi.number().integer().required(),
  }),

  adminRemoveMember: Joi.object({
    motivo: Joi.string().required().min(10).max(2000),
  }),
};
