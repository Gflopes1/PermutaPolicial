// /src/modules/mapa-tatico/mapa-tatico.service.js

const mapaTaticoRepository = require('./mapa-tatico.repository');
const policiaisOAuthRepository = require('../policiais/policiais.oauth.repository');
const mapaTaticoStorage = require('./mapa-tatico-storage.service');
const ApiError = require('../../core/utils/ApiError');

const OPERATIONAL_TYPES = ['ocorrencia_recente', 'suspeito', 'local_interesse'];
const LOGISTICS_TYPES = ['restaurante', 'padaria', 'base'];

function getExpiresAtForType(type) {
  if (type === 'ocorrencia_recente') {
    const d = new Date();
    d.setDate(d.getDate() + 7);
    return d;
  }
  return null;
}

// ========== GRUPOS ==========
async function createGroup(req) {
  const { name } = req.body;
  const creatorId = req.user.id;
  return await mapaTaticoRepository.createGroup(name, creatorId);
}

async function getGroups(req) {
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

  const policial = await policiaisOAuthRepository.findByEmail(email.toLowerCase().trim());
  if (!policial) {
    throw new ApiError(404, 'Nenhum usuário cadastrado com este e-mail.');
  }
  const existingMember = await mapaTaticoRepository.findMember(groupId, policial.id);
  if (existingMember) {
    throw new ApiError(400, 'Este usuário já é membro do grupo.');
  }
  const pendingInvite = await mapaTaticoRepository.findPendingInviteByGroupAndEmail(groupId, email);
  if (pendingInvite) {
    throw new ApiError(400, 'Já existe um convite pendente para este e-mail.');
  }

  await mapaTaticoRepository.createInvite(groupId, email, invitedById);
  return { success: true, message: 'Convite enviado. O usuário pode aceitar no app.' };
}

async function getPendingInvites(req) {
  const email = req.user.email;
  if (!email) return [];
  const db = require('../../config/db');
  const [rows] = await db.execute(
    `SELECT i.*, g.name as group_name FROM map_group_invites i
     JOIN map_groups g ON i.group_id = g.id
     WHERE i.email = ? AND i.status = ?`,
    [email, 'PENDING']
  );
  return rows;
}

async function acceptInvite(req) {
  const inviteId = parseInt(req.params.inviteId);
  const userId = req.user.id;
  const userEmail = req.user.email?.toLowerCase().trim();
  const db = require('../../config/db');
  const [invites] = await db.execute('SELECT * FROM map_group_invites WHERE id = ? AND status = ?', [inviteId, 'PENDING']);
  if (invites.length === 0) {
    throw new ApiError(404, 'Convite não encontrado ou já utilizado.');
  }
  const invite = invites[0];
  if (invite.email.toLowerCase().trim() !== userEmail) {
    throw new ApiError(403, 'Este convite não é para o seu e-mail.');
  }
  const result = await mapaTaticoRepository.acceptInvite(inviteId, userId);
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

  const member = await mapaTaticoRepository.findMember(groupId, creatorId);
  if (!member) throw new ApiError(403, 'Você não é membro deste grupo.');
  if (member.is_muted) throw new ApiError(403, 'Você está mutado e não pode criar pontos.');

  let photoUrl = null;
  if (req.file && req.file.buffer) {
    photoUrl = await mapaTaticoStorage.uploadPhoto(req.file.buffer, req.file.mimetype);
  }

  let expiresAt = body.expires_at ? new Date(body.expires_at) : null;
  if (body.type === 'ocorrencia_recente' && !expiresAt) {
    expiresAt = getExpiresAtForType('ocorrencia_recente');
  }

  const point = await mapaTaticoRepository.createPoint({
    groupId,
    creatorId,
    title: body.title,
    address: body.address || null,
    lat: parseFloat(body.lat),
    lng: parseFloat(body.lng),
    type: body.type,
    mapType: body.map_type,
    expiresAt,
    photoUrl,
  });

  await mapaTaticoRepository.createAuditLog(point.id, creatorId, 'CREATE', { title: point.title });
  return point;
}

async function getPoints(req) {
  const groupId = parseInt(req.query.group_id);
  const mapType = req.query.map_type || null;
  if (!groupId) throw new ApiError(400, 'group_id é obrigatório.');
  const member = await mapaTaticoRepository.findMember(groupId, req.user.id);
  if (!member) throw new ApiError(403, 'Você não é membro deste grupo.');
  return await mapaTaticoRepository.findPointsByGroup(groupId, mapType);
}

async function getPoint(req) {
  return req.point;
}

async function updatePoint(req) {
  const point = req.point;
  const body = req.body;

  const updateData = {};
  if (body.title !== undefined) updateData.title = body.title;
  if (body.address !== undefined) updateData.address = body.address;
  if (body.lat !== undefined) updateData.lat = body.lat;
  if (body.lng !== undefined) updateData.lng = body.lng;
  if (body.type !== undefined) updateData.type = body.type;
  if (body.map_type !== undefined) updateData.map_type = body.map_type;
  if (body.expires_at !== undefined) updateData.expires_at = body.expires_at ? new Date(body.expires_at) : null;
  if (req.file && req.file.buffer) {
    updateData.photo_url = await mapaTaticoStorage.uploadPhoto(req.file.buffer, req.file.mimetype);
  }

  const updated = await mapaTaticoRepository.updatePoint(point.id, updateData);
  await mapaTaticoRepository.createAuditLog(point.id, req.user.id, 'UPDATE', { changes: Object.keys(updateData) });
  return updated;
}

async function deletePoint(req) {
  const point = req.point;
  await mapaTaticoRepository.softDeletePoint(point.id);
  await mapaTaticoRepository.createAuditLog(point.id, req.user.id, 'DELETE', {});
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

  return await mapaTaticoRepository.createComment(point.id, userId, text);
}

async function getComments(req) {
  return await mapaTaticoRepository.findCommentsByPointId(req.point.id);
}

// ========== DENÚNCIAS ==========
async function reportPoint(req) {
  const point = req.point;
  const userId = req.user.id;
  const member = await mapaTaticoRepository.findMember(point.group_id, userId);
  if (!member) throw new ApiError(403, 'Você não é membro deste grupo.');

  await mapaTaticoRepository.createReport(point.id, userId, req.body.reason || null);
  await mapaTaticoRepository.createAuditLog(point.id, userId, 'REPORT', { reason: req.body.reason });
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
  return await mapaTaticoRepository.findVisitsByPointId(req.point.id, lastDays);
}

// ========== AUDITORIA ==========
async function getAudit(req) {
  return await mapaTaticoRepository.findAuditLogsByPointId(req.point.id);
}

module.exports = {
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
};
