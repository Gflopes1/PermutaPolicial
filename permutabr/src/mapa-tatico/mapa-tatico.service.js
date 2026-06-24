// /src/modules/mapa-tatico/mapa-tatico.service.js

const mapaTaticoRepository = require('./mapa-tatico.repository');
const policiaisOAuthRepository = require('../policiais/policiais.oauth.repository');
const mapaTaticoStorage = require('./mapa-tatico-storage.service');
const {
  emitPointCreated,
  emitPointUpdated,
  emitPointDeleted,
  emitCommentAdded,
  emitMemberJoined,
  emitMemberLocationUpdated,
} = require('./mapa-tatico.socket');
const mapaTaticoNotifications = require('./mapa-tatico.notifications.service');
const mapaTaticoGeocode = require('./mapa-tatico.geocode.service');
const {
  isHealthType,
  isNationalInfraType,
  NATIONAL_TYPES,
  MAP_TYPES,
  resolveMapTypeForPoint,
} = require('./mapa-tatico.types');
const storageService = require('../../core/services/storage.service');
const ApiError = require('../../core/utils/ApiError');
const {
  MAX_GROUP_MEMBERS,
  REPORT_RATE_LIMIT_HOURS,
  REPORT_RATE_LIMIT_MAX,
  normalizeEmail,
  validateBrazilCoordinates,
  sanitizeCommentText,
  sanitizeAuditMetadata,
  getInviteExpiresAt,
  getExpiresAtForPointType,
} = require('./mapa-tatico-security.utils');

const INVITE_GENERIC_MESSAGE =
  'Convite enviado. Se o e-mail estiver cadastrado, o usuário será notificado.';

// ========== GRUPOS ==========
async function getStatus() {
  return {
    photo_upload_enabled: mapaTaticoStorage.isStorageConfigured(),
    storage: storageService.getConfig?.() || {},
  };
}

async function createGroup(req) {
  const { name } = req.body;
  const creatorId = req.user.id;
  return await mapaTaticoRepository.createGroup(name, creatorId);
}

async function getGroups(req) {
  await mapaTaticoRepository.ensureGlobalGroupMembership(req.user.id);
  return await mapaTaticoRepository.findGroupsByUserId(req.user.id);
}

async function switchGroup(req) {
  const groupId = parseInt(req.params.id);
  const member = await mapaTaticoRepository.findMember(groupId, req.user.id);
  if (!member) {
    throw new ApiError(403, 'Você não é membro deste grupo.');
  }
  return { success: true, group_id: groupId };
}

async function leaveGroup(req) {
  const groupId = parseInt(req.params.id);
  const userId = req.user.id;
  const group = await mapaTaticoRepository.findGroupById(groupId);
  if (group?.is_global) {
    throw new ApiError(400, 'Não é possível sair do Mapa Nacional Colaborativo.');
  }
  const member = await mapaTaticoRepository.findMember(groupId, userId);
  if (!member) throw new ApiError(403, 'Você não é membro deste grupo.');

  if (member.role === 'MODERATOR') {
    const moderatorCount = await mapaTaticoRepository.countGroupModerators(groupId);
    if (moderatorCount <= 1) {
      throw new ApiError(400, 'Você é o último moderador do grupo. Promova outro moderador antes de sair.');
    }
  }

  const removed = await mapaTaticoRepository.removeMember(groupId, userId);
  if (!removed) throw new ApiError(500, 'Não foi possível sair do grupo.');
  return { success: true, message: 'Você saiu do grupo.' };
}

async function inviteToGroup(req) {
  const groupId = req.groupId;
  const { email } = req.body;
  const invitedById = req.user.id;
  const member = req.groupMember;
  if (member.role !== 'MODERATOR' && !req.user.is_moderator && !req.user.embaixador) {
    throw new ApiError(403, 'Apenas moderadores do grupo ou moderadores gerais do site podem convidar.');
  }

  const memberCount = await mapaTaticoRepository.countGroupMembers(groupId);
  if (memberCount >= MAX_GROUP_MEMBERS) {
    throw new ApiError(400, `O grupo atingiu o limite de ${MAX_GROUP_MEMBERS} membros.`);
  }

  const normalizedEmail = normalizeEmail(email);
  const policial = await policiaisOAuthRepository.findByEmail(normalizedEmail);

  if (!policial) {
    return { success: true, message: INVITE_GENERIC_MESSAGE };
  }

  const existingMember = await mapaTaticoRepository.findMember(groupId, policial.id);
  if (existingMember) {
    return { success: true, message: INVITE_GENERIC_MESSAGE };
  }

  const pendingInvite = await mapaTaticoRepository.findPendingInviteByGroupAndEmail(groupId, normalizedEmail);
  if (pendingInvite) {
    return { success: true, message: INVITE_GENERIC_MESSAGE };
  }

  const inviteExpires = getInviteExpiresAt();
  await mapaTaticoRepository.createInvite(
    groupId,
    normalizedEmail,
    invitedById,
    inviteExpires
  );

  const group = await mapaTaticoRepository.findGroupById(groupId);
  if (policial) {
    await mapaTaticoNotifications.notifyUser(policial.id, {
      tipo: 'MAPA_TATICO_CONVITE',
      referenciaId: groupId,
      titulo: 'Convite para mapa tático',
      mensagem: `Você foi convidado para o grupo "${group?.name || 'Mapa tático'}".`,
    });
  }
  unawaited(mapaTaticoNotifications.notifyGroupInvite(normalizedEmail, group?.name || 'Mapa tático', groupId));

  return { success: true, message: INVITE_GENERIC_MESSAGE };
}

function unawaited(promise) {
  promise.catch(() => {});
}

async function getPendingInvites(req) {
  const email = normalizeEmail(req.user.email);
  if (!email) return [];
  return await mapaTaticoRepository.findPendingInvitesByEmail(email);
}

async function acceptInvite(req) {
  const inviteId = parseInt(req.params.inviteId);
  const userId = req.user.id;
  const userEmail = normalizeEmail(req.user.email);

  const db = require('../../config/db');
  const [invites] = await db.execute(
    `SELECT * FROM map_group_invites
     WHERE id = ? AND status = ? AND (expires_at IS NULL OR expires_at > NOW())`,
    [inviteId, 'PENDING']
  );
  if (invites.length === 0) {
    throw new ApiError(404, 'Convite não encontrado, expirado ou já utilizado.');
  }
  const invite = invites[0];
  if (normalizeEmail(invite.email) !== userEmail) {
    throw new ApiError(403, 'Este convite não é para o seu e-mail.');
  }

  const memberCount = await mapaTaticoRepository.countGroupMembers(invite.group_id);
  if (memberCount >= MAX_GROUP_MEMBERS) {
    throw new ApiError(400, 'O grupo atingiu o limite de membros.');
  }

  const result = await mapaTaticoRepository.acceptInvite(inviteId, userId);
  if (!result) {
    throw new ApiError(404, 'Convite não encontrado ou expirado.');
  }
  const members = await mapaTaticoRepository.findGroupMembers(result.id);
  const joined = members.find((m) => m.user_id === userId);
  if (joined) {
    emitMemberJoined(result.id, joined);
  }
  return result;
}

async function rejectInvite(req) {
  const inviteId = parseInt(req.params.inviteId);
  const userId = req.user.id;
  const success = await mapaTaticoRepository.rejectInvite(inviteId, userId);
  if (!success) {
    throw new ApiError(404, 'Convite não encontrado ou não é seu para recusar.');
  }
  return { success: true, message: 'Convite recusado.' };
}

async function getGroupMembers(req) {
  const groupId = req.groupId ?? parseInt(req.params.id) ?? parseInt(req.params.groupId);
  const member = await mapaTaticoRepository.findMember(groupId, req.user.id);
  if (!member && !req.user.is_moderator && !req.user.embaixador) {
    throw new ApiError(403, 'Você não é membro deste grupo.');
  }
  return await mapaTaticoRepository.findGroupMembers(groupId);
}

async function removeMember(req) {
  const groupId = parseInt(req.params.groupId);
  const targetUserId = parseInt(req.params.userId);
  const member = await mapaTaticoRepository.findMember(groupId, req.user.id);
  if (!member) throw new ApiError(403, 'Você não é membro deste grupo.');
  if (member.role !== 'MODERATOR' && !req.user.is_moderator && !req.user.embaixador) {
    throw new ApiError(403, 'Apenas moderadores do grupo ou moderadores gerais do site podem remover usuários.');
  }
  const targetMember = await mapaTaticoRepository.findMember(groupId, targetUserId);
  if (!targetMember) throw new ApiError(404, 'Usuário não encontrado no grupo.');
  if (targetMember.role === 'MODERATOR') {
    throw new ApiError(400, 'Não é possível remover moderadores do grupo.');
  }
  const removed = await mapaTaticoRepository.removeMember(groupId, targetUserId);
  if (!removed) throw new ApiError(500, 'Erro ao remover usuário.');
  return { success: true, message: 'Usuário removido do grupo.' };
}

async function promoteMember(req) {
  const groupId = parseInt(req.params.groupId);
  const targetUserId = parseInt(req.params.userId);
  const member = await mapaTaticoRepository.findMember(groupId, req.user.id);
  if (!member) throw new ApiError(403, 'Você não é membro deste grupo.');
  if (member.role !== 'MODERATOR' && !req.user.is_moderator && !req.user.embaixador) {
    throw new ApiError(403, 'Apenas moderadores do grupo ou moderadores gerais do site podem promover usuários.');
  }
  const targetMember = await mapaTaticoRepository.findMember(groupId, targetUserId);
  if (!targetMember) throw new ApiError(404, 'Usuário não encontrado no grupo.');
  if (targetMember.role === 'MODERATOR') {
    throw new ApiError(400, 'Este usuário já é moderador do grupo.');
  }
  const updated = await mapaTaticoRepository.updateMemberRole(groupId, targetUserId, 'MODERATOR');
  if (!updated) throw new ApiError(500, 'Erro ao promover usuário.');
  return { success: true, message: 'Usuário promovido a moderador.' };
}

async function updateNomeDeGuerra(req) {
  const groupId = req.groupId;
  const userId = req.user.id;
  const { nome_de_guerra } = req.body;
  return await mapaTaticoRepository.updateNomeDeGuerra(groupId, userId, nome_de_guerra || null);
}

async function updateMemberNomeDeGuerra(req) {
  const groupId = parseInt(req.params.groupId);
  const targetUserId = parseInt(req.params.userId);
  const { nome_de_guerra } = req.body;
  const actorMember = await mapaTaticoRepository.findMember(groupId, req.user.id);
  if (!actorMember) throw new ApiError(403, 'Você não é membro deste grupo.');
  const isSiteModerator = !!req.user.is_moderator || !!req.user.embaixador;
  const isGroupModerator = actorMember.role === 'MODERATOR';
  const isSelfUpdate = req.user.id === targetUserId;
  if (!isSelfUpdate && !isGroupModerator && !isSiteModerator) {
    throw new ApiError(403, 'Apenas moderadores podem alterar o nome de guerra de outros membros.');
  }
  const targetMember = await mapaTaticoRepository.findMember(groupId, targetUserId);
  if (!targetMember) throw new ApiError(404, 'Usuário não encontrado no grupo.');
  return await mapaTaticoRepository.updateMemberNomeDeGuerra(groupId, targetUserId, nome_de_guerra || null);
}

async function muteMember(req) {
  const groupId = parseInt(req.params.groupId);
  const targetUserId = parseInt(req.params.userId);
  const { is_muted } = req.body;
  const member = await mapaTaticoRepository.findMember(groupId, req.user.id);
  if (!member) throw new ApiError(403, 'Você não é membro deste grupo.');
  if (member.role !== 'MODERATOR' && !req.user.is_moderator && !req.user.embaixador) {
    throw new ApiError(403, 'Apenas moderadores do grupo ou moderadores gerais do site podem mutar usuários.');
  }
  const targetMember = await mapaTaticoRepository.findMember(groupId, targetUserId);
  if (!targetMember) throw new ApiError(404, 'Usuário não encontrado no grupo.');
  if (targetMember.role === 'MODERATOR') {
    throw new ApiError(400, 'Não é possível mutar moderadores.');
  }
  await mapaTaticoRepository.setMuted(groupId, targetUserId, is_muted);
  return { success: true, is_muted: !!is_muted };
}

// ========== PONTOS ==========
async function createPoint(req) {
  const body = req.body;
  const groupId = parseInt(body.group_id);
  const creatorId = req.user.id;

  const group = await mapaTaticoRepository.findGroupById(groupId);
  if (!group) throw new ApiError(404, 'Grupo não encontrado.');

  const member = await mapaTaticoRepository.findMember(groupId, creatorId);
  if (!member) throw new ApiError(403, 'Você não é membro deste grupo.');
  if (member.is_muted) throw new ApiError(403, 'Você está mutado e não pode criar pontos.');

  if (isNationalInfraType(body.type) && !group.is_global) {
    throw new ApiError(400, 'Este tipo de ponto só pode ser criado no Mapa Nacional.');
  }
  if (isNationalInfraType(body.type) && !NATIONAL_TYPES.includes(body.type)) {
    throw new ApiError(400, 'Tipo de ponto inválido para o mapa nacional.');
  }

  const resolvedMapType = resolveMapTypeForPoint(body.type, body.map_type);

  const coords = validateBrazilCoordinates(body.lat, body.lng);

  let photoUrl = null;
  if (req.file && req.file.buffer) {
    photoUrl = await mapaTaticoStorage.uploadPhoto(req.file.buffer, req.file.mimetype);
  }
  let expiresAt = body.expires_at ? new Date(body.expires_at) : null;
  if (!expiresAt) {
    expiresAt = getExpiresAtForPointType(body.type);
  }

  const point = await mapaTaticoRepository.createPoint({
    groupId,
    creatorId,
    title: body.title,
    address: body.address || null,
    description: body.description || null,
    lat: coords.lat,
    lng: coords.lng,
    type: body.type,
    mapType: resolvedMapType,
    expiresAt,
    photoUrl,
  });

  // Auditoria e notificações fora do caminho crítico da resposta.
  unawaited(
    mapaTaticoRepository.createAuditLog(
      point.id,
      creatorId,
      'CREATE',
      sanitizeAuditMetadata({ map_type: point.map_type })
    )
  );
  emitPointCreated(groupId, point);
  unawaited(mapaTaticoNotifications.notifyOperationalPointCreated(point, creatorId));
  return point;
}

async function getPoints(req) {
  const groupId = parseInt(req.query.group_id);
  const mapType = req.query.map_type;
  if (!groupId) throw new ApiError(400, 'group_id é obrigatório.');
  if (!mapType || ![...MAP_TYPES, 'ALL'].includes(mapType)) {
    throw new ApiError(400, 'map_type é obrigatório (OPERATIONAL, LOGISTICS, SHARED ou ALL).');
  }
  const member = await mapaTaticoRepository.findMember(groupId, req.user.id);
  if (!member) throw new ApiError(403, 'Você não é membro deste grupo.');

  const since = req.query.since ? new Date(req.query.since) : null;
  const points = await mapaTaticoRepository.findPointsByGroup(
    groupId,
    mapType,
    since && !Number.isNaN(since.getTime()) ? since : null
  );

  if (mapType === 'OPERATIONAL' && points.length > 0) {
    // Log de leitura não bloqueia a resposta.
    unawaited(
      mapaTaticoRepository.createAuditLog(
        points[0].id,
        req.user.id,
        'READ',
        sanitizeAuditMetadata({ map_type: 'OPERATIONAL', list: true, group_id: groupId, count: points.length })
      )
    );
  }

  return points;
}

async function getPoint(req) {
  const point = req.point;
  if (point.map_type === 'OPERATIONAL') {
    unawaited(
      mapaTaticoRepository.createAuditLog(
        point.id,
        req.user.id,
        'READ',
        sanitizeAuditMetadata({ map_type: 'OPERATIONAL' })
      )
    );
  }
  return point;
}

async function updatePoint(req) {
  const point = req.point;
  const body = req.body;

  const updateData = {};
  if (body.title !== undefined) updateData.title = body.title;
  if (body.address !== undefined) updateData.address = body.address;
  if (body.description !== undefined) updateData.description = body.description;
  if (body.lat !== undefined || body.lng !== undefined) {
    const lat = body.lat !== undefined ? body.lat : point.lat;
    const lng = body.lng !== undefined ? body.lng : point.lng;
    const coords = validateBrazilCoordinates(lat, lng);
    updateData.lat = coords.lat;
    updateData.lng = coords.lng;
  }
  if (body.type !== undefined) updateData.type = body.type;
  if (body.map_type !== undefined) updateData.map_type = body.map_type;
  if (body.expires_at !== undefined) {
    updateData.expires_at = body.expires_at ? new Date(body.expires_at) : null;
  }
  if (req.file && req.file.buffer) {
    if (point.photo_url) {
      await mapaTaticoStorage.deletePhoto(point.photo_url);
    }
    updateData.photo_url = await mapaTaticoStorage.uploadPhoto(req.file.buffer, req.file.mimetype);
  }

  const updated = await mapaTaticoRepository.updatePoint(point.id, updateData);
  unawaited(
    mapaTaticoRepository.createAuditLog(
      point.id,
      req.user.id,
      'UPDATE',
      sanitizeAuditMetadata({ changes: Object.keys(updateData) })
    )
  );
  emitPointUpdated(point.group_id, updated);
  return updated;
}

async function deletePoint(req) {
  const point = req.point;
  const groupId = point.group_id;
  const pointId = point.id;
  const mapType = point.map_type;

  if (point.map_type === 'OPERATIONAL') {
    if (point.photo_url) {
      await mapaTaticoStorage.deletePhoto(point.photo_url);
    }
    await mapaTaticoRepository.hardDeletePoint(point.id);
  } else {
    await mapaTaticoRepository.softDeletePoint(point.id);
    await mapaTaticoRepository.createAuditLog(
      point.id,
      req.user.id,
      'DELETE',
      sanitizeAuditMetadata({ map_type: 'LOGISTICS' })
    );
  }

  emitPointDeleted(groupId, pointId, mapType);
  return { success: true };
}

// ========== COMENTÁRIOS ==========
async function createComment(req) {
  const point = req.point;
  const { text } = req.body;
  const userId = req.user.id;

  const member = await mapaTaticoRepository.findMember(point.group_id, userId);
  if (!member) throw new ApiError(403, 'Você não é membro deste grupo.');
  if (member.is_muted) throw new ApiError(403, 'Você está mutado e não pode comentar.');

  const safeText = sanitizeCommentText(text);
  if (!safeText) throw new ApiError(400, 'Comentário inválido.');

  const comment = await mapaTaticoRepository.createComment(point.id, userId, safeText);
  emitCommentAdded(point.group_id, point.id, comment);
  unawaited(mapaTaticoNotifications.notifyPointComment(point, comment, userId));
  return comment;
}

async function getComments(req) {
  const limit = req.query.limit || 50;
  const offset = req.query.offset || 0;
  return await mapaTaticoRepository.findCommentsByPointId(req.point.id, limit, offset);
}

// ========== DENÚNCIAS ==========
async function reportPoint(req) {
  const point = req.point;
  const userId = req.user.id;
  const member = await mapaTaticoRepository.findMember(point.group_id, userId);
  if (!member) throw new ApiError(403, 'Você não é membro deste grupo.');

  const recentCount = await mapaTaticoRepository.countRecentReportsByUser(
    point.id,
    userId,
    REPORT_RATE_LIMIT_HOURS
  );
  if (recentCount >= REPORT_RATE_LIMIT_MAX) {
    throw new ApiError(429, 'Limite de denúncias atingido. Tente novamente mais tarde.');
  }

  await mapaTaticoRepository.createReport(point.id, userId, req.body.reason || null);
  await mapaTaticoRepository.createAuditLog(
    point.id,
    userId,
    'REPORT',
    sanitizeAuditMetadata({ has_reason: !!req.body.reason })
  );
  unawaited(mapaTaticoNotifications.notifyReportToModerators(point, userId));
  return { success: true, message: 'Denúncia registrada.' };
}

// ========== VISITAS ==========
async function createVisit(req) {
  const point = req.point;
  const userId = req.user.id;
  if (point.map_type !== 'LOGISTICS') {
    throw new ApiError(400, 'Apenas pontos logísticos podem receber registro de visita.');
  }
  const member = await mapaTaticoRepository.findMember(point.group_id, userId);
  if (!member) throw new ApiError(403, 'Você não é membro deste grupo.');

  await mapaTaticoRepository.createVisit(point.id, userId);
  return { success: true, message: 'Visita registrada.' };
}

async function getVisits(req) {
  const lastDays = parseInt(req.query.lastDays) || 7;
  const limit = req.query.limit || 50;
  const offset = req.query.offset || 0;
  return await mapaTaticoRepository.findVisitsByPointId(req.point.id, lastDays, limit, offset);
}

// ========== AUDITORIA ==========
async function getAudit(req) {
  return await mapaTaticoRepository.findAuditLogsByPointId(req.point.id);
}

// ========== GEOCODE ==========
async function geocodeSearch(req) {
  return await mapaTaticoGeocode.searchAddress(req.query.q);
}

async function geocodeReverse(req) {
  return await mapaTaticoGeocode.reverseGeocode(req.query.lat, req.query.lng);
}

// ========== LOCALIZAÇÃO DA EQUIPE ==========
async function updateMemberLocation(req) {
  const groupId = parseInt(req.params.id);
  const userId = req.user.id;
  const { lat, lng, sharing_enabled: sharingEnabled } = req.body;

  const member = await mapaTaticoRepository.findMember(groupId, userId);
  if (!member) throw new ApiError(403, 'Você não é membro deste grupo.');

  const coords = validateBrazilCoordinates(lat, lng);
  const location = await mapaTaticoRepository.upsertMemberLocation(
    groupId,
    userId,
    coords.lat,
    coords.lng,
    sharingEnabled !== false
  );

  if (sharingEnabled !== false) {
    emitMemberLocationUpdated(groupId, location);
    unawaited(
      mapaTaticoNotifications.checkProximityAlerts(userId, groupId, coords.lat, coords.lng, 200)
    );
  }

  return location;
}

async function getMemberLocations(req) {
  const groupId = parseInt(req.params.id);
  const member = await mapaTaticoRepository.findMember(groupId, req.user.id);
  if (!member) throw new ApiError(403, 'Você não é membro deste grupo.');

  const maxAge = parseInt(req.query.max_age_minutes) || 30;
  return await mapaTaticoRepository.findActiveMemberLocations(groupId, maxAge);
}

async function stopSharingLocation(req) {
  const groupId = parseInt(req.params.id);
  const userId = req.user.id;
  const member = await mapaTaticoRepository.findMember(groupId, userId);
  if (!member) throw new ApiError(403, 'Você não é membro deste grupo.');

  await mapaTaticoRepository.setMemberLocationSharing(groupId, userId, false);
  return { success: true };
}

// ========== INTELIGÊNCIA ==========
async function getIntelligence(req) {
  const groupId = parseInt(req.params.id);
  const mapType = req.query.map_type;
  const days = parseInt(req.query.days) || 7;
  if (!['OPERATIONAL', 'LOGISTICS'].includes(mapType)) {
    throw new ApiError(400, 'map_type é obrigatório (OPERATIONAL ou LOGISTICS).');
  }
  const member = await mapaTaticoRepository.findMember(groupId, req.user.id);
  if (!member) throw new ApiError(403, 'Você não é membro deste grupo.');
  return await mapaTaticoRepository.getGroupIntelligence(groupId, mapType, days);
}

// ========== DENÚNCIAS ADMIN ==========
async function listReports(req) {
  const isSiteAdmin = !!req.user.is_moderator || !!req.user.embaixador;
  return await mapaTaticoRepository.findPendingReportsForUser(req.user.id, isSiteAdmin);
}

async function reviewReport(req) {
  const reportId = parseInt(req.params.reportId);
  const { status, admin_notes: adminNotes } = req.body;
  if (!['REVIEWED', 'DISMISSED'].includes(status)) {
    throw new ApiError(400, 'status inválido.');
  }
  const isSiteAdmin = !!req.user.is_moderator || !!req.user.embaixador;
  const reports = await mapaTaticoRepository.findPendingReportsForUser(req.user.id, isSiteAdmin);
  if (!reports.some((r) => r.id === reportId)) {
    throw new ApiError(403, 'Sem permissão para revisar esta denúncia.');
  }
  await mapaTaticoRepository.updateReportStatus(reportId, status, req.user.id, adminNotes || null);
  return { success: true };
}

module.exports = {
  getStatus,
  createGroup,
  getGroups,
  switchGroup,
  leaveGroup,
  inviteToGroup,
  getPendingInvites,
  acceptInvite,
  rejectInvite,
  getGroupMembers,
  updateNomeDeGuerra,
  updateMemberNomeDeGuerra,
  muteMember,
  removeMember,
  promoteMember,
  createPoint,
  getPoints,
  getPoint,
  updatePoint,
  deletePoint,
  createComment,
  getComments,
  reportPoint,
  createVisit,
  getVisits,
  getAudit,
  geocodeSearch,
  geocodeReverse,
  updateMemberLocation,
  getMemberLocations,
  stopSharingLocation,
  getIntelligence,
  listReports,
  reviewReport,
};
