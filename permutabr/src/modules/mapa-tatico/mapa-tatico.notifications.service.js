// Notificações in-app, push FCM e e-mail do mapa tático

const notificacoesRepository = require('../notificacoes/notificacoes.repository');
const { sendPushToUser } = require('../push/push.sender');
const emailService = require('../../core/services/email.service');
const mapaTaticoRepository = require('./mapa-tatico.repository');
const logger = require('../../core/utils/logger');

const EARTH_RADIUS_M = 6371000;

function haversineMeters(lat1, lng1, lat2, lng2) {
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_M * Math.asin(Math.sqrt(a));
}

async function createInApp(userId, { tipo, referenciaId, titulo, mensagem }) {
  try {
    await notificacoesRepository.create({
      usuario_id: userId,
      tipo,
      referencia_id: referenciaId,
      titulo,
      mensagem,
    });
  } catch (error) {
    logger.error('[mapa-tatico] Falha notificação in-app', { userId, tipo, error: error.message });
  }
}

async function sendPush(userId, { title, body, data = {} }) {
  try {
    const result = await sendPushToUser(userId, { title, body, data });
    if (result.skipped) {
      logger.debug('[mapa-tatico] Push ignorado', { userId, reason: result.skipped });
    }
  } catch (error) {
    logger.error('[mapa-tatico] Falha push', { userId, error: error.message });
  }
}

async function notifyUser(userId, payload) {
  await createInApp(userId, payload);
  await sendPush(userId, {
    title: payload.titulo,
    body: payload.mensagem,
    data: {
      tipo: payload.tipo,
      referencia_id: String(payload.referenciaId || ''),
    },
  });
}

async function notifyGroupMembers(groupId, exceptUserId, payload) {
  const members = await mapaTaticoRepository.findGroupMembers(groupId);
  for (const member of members) {
    if (member.user_id === exceptUserId) continue;
    await notifyUser(member.user_id, payload);
  }
}

async function notifyOperationalPointCreated(point, creatorId) {
  if (point.map_type !== 'OPERATIONAL') return;
  await notifyGroupMembers(point.group_id, creatorId, {
    tipo: 'MAPA_TATICO_PONTO',
    referenciaId: point.id,
    titulo: 'Novo ponto operacional',
    mensagem: `${point.title} foi adicionado ao mapa.`,
  });
}

async function notifyPointComment(point, comment, authorId) {
  if (point.creator_id === authorId) return;
  await notifyUser(point.creator_id, {
    tipo: 'MAPA_TATICO_COMENTARIO',
    referenciaId: point.id,
    titulo: 'Comentário no seu ponto',
    mensagem: `Novo comentário em "${point.title}".`,
  });
}

async function notifyGroupInvite(email, groupName, inviteId) {
  try {
    await emailService.sendMapaTaticoInviteEmail(email, groupName, inviteId);
  } catch (error) {
    logger.error('[mapa-tatico] Falha e-mail convite', { email, error: error.message });
  }
}

async function notifyReportToModerators(point, reporterId) {
  const members = await mapaTaticoRepository.findGroupMembers(point.group_id);
  const siteMods = members.filter((m) => false);
  void siteMods;

  const moderators = members.filter((m) => m.role === 'MODERATOR' && m.user_id !== reporterId);
  for (const mod of moderators) {
    await notifyUser(mod.user_id, {
      tipo: 'MAPA_TATICO_DENUNCIA',
      referenciaId: point.id,
      titulo: 'Denúncia no mapa tático',
      mensagem: `Ponto "${point.title}" foi denunciado.`,
    });
  }
}

const { PROXIMITY_ALERT_TYPES } = require('./mapa-tatico.types');

async function checkProximityAlerts(userId, groupId, lat, lng, radiusMeters = 200) {
  const points = await mapaTaticoRepository.findPointsByGroup(groupId, 'OPERATIONAL');
  for (const point of points) {
    if (!PROXIMITY_ALERT_TYPES.includes(point.type)) continue;
    const distance = haversineMeters(lat, lng, parseFloat(point.lat), parseFloat(point.lng));
    if (distance <= radiusMeters) {
      await notifyUser(userId, {
        tipo: 'MAPA_TATICO_PROXIMIDADE',
        referenciaId: point.id,
        titulo: 'Ponto operacional próximo',
        mensagem: `Você está a ${Math.round(distance)} m de "${point.title}".`,
      });
      break;
    }
  }
}

module.exports = {
  notifyOperationalPointCreated,
  notifyPointComment,
  notifyGroupInvite,
  notifyReportToModerators,
  checkProximityAlerts,
  notifyGroupMembers,
  notifyUser,
};
