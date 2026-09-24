// Emissão de eventos em tempo real para salas do mapa tático

const { getIO } = require('../../config/socket');
const { groupRoom } = require('./mapa-tatico.socket.constants');

function emitToGroup(groupId, event, payload) {
  try {
    const io = getIO();
    io.to(groupRoom(groupId)).emit(event, payload);
  } catch (error) {
    console.error(`[mapa-tatico.socket] Falha ao emitir ${event}:`, error.message);
  }
}

function emitToUser(userId, event, payload) {
  try {
    const io = getIO();
    io.to(`user_${userId}`).emit(event, payload);
  } catch (error) {
    console.error(`[mapa-tatico.socket] Falha ao emitir ${event} para user_${userId}:`, error.message);
  }
}

function serializePointRow(row) {
  if (!row) return null;
  return {
    id: row.id,
    group_id: row.group_id,
    creator_id: row.creator_id,
    title: row.title,
    description: row.description,
    address: row.address,
    lat: row.lat,
    lng: row.lng,
    type: row.type,
    map_type: row.map_type,
    visibility: row.visibility || 'GROUP',
    expires_at: row.expires_at,
    photo_url: row.photo_url,
    photos: row.photos || [],
    created_at: row.created_at,
    creator_nome_guerra: row.creator_nome_guerra,
    creator_nome: row.creator_nome,
  };
}

function serializeCommentRow(row) {
  if (!row) return null;
  return {
    id: row.id,
    point_id: row.point_id,
    user_id: row.user_id,
    text: row.text,
    created_at: row.created_at,
    author_display_name: row.author_display_name,
  };
}

function emitPointCreated(groupId, point) {
  const payload = { point: serializePointRow(point) };
  if (point.visibility === 'PRIVATE') {
    emitToUser(point.creator_id, 'mapa_tatico_point_created', payload);
    return;
  }
  emitToGroup(groupId, 'mapa_tatico_point_created', payload);
}

function emitPointUpdated(groupId, point) {
  const payload = { point: serializePointRow(point) };
  if (point.visibility === 'PRIVATE') {
    emitToUser(point.creator_id, 'mapa_tatico_point_updated', payload);
    return;
  }
  emitToGroup(groupId, 'mapa_tatico_point_updated', payload);
}

function emitPointDeleted(groupId, pointId, mapType, point = null) {
  const payload = {
    point_id: pointId,
    map_type: mapType,
  };
  if (point?.visibility === 'PRIVATE') {
    emitToUser(point.creator_id, 'mapa_tatico_point_deleted', payload);
    return;
  }
  emitToGroup(groupId, 'mapa_tatico_point_deleted', payload);
}

function emitCommentAdded(groupId, pointId, comment, point = null) {
  const payload = {
    point_id: pointId,
    comment: serializeCommentRow(comment),
  };
  if (point?.visibility === 'PRIVATE') {
    emitToUser(point.creator_id, 'mapa_tatico_comment_added', payload);
    return;
  }
  emitToGroup(groupId, 'mapa_tatico_comment_added', payload);
}

function emitMemberJoined(groupId, member) {
  emitToGroup(groupId, 'mapa_tatico_member_joined', { member });
}

function emitMemberLocationUpdated(groupId, location) {
  emitToGroup(groupId, 'mapa_tatico_location_updated', { location });
}

module.exports = {
  emitToGroup,
  emitToUser,
  emitPointCreated,
  emitPointUpdated,
  emitPointDeleted,
  emitCommentAdded,
  emitMemberJoined,
  emitMemberLocationUpdated,
  serializePointRow,
};
