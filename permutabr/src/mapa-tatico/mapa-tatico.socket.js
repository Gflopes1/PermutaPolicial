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

function serializePointRow(row) {
  if (!row) return null;
  return {
    id: row.id,
    group_id: row.group_id,
    creator_id: row.creator_id,
    title: row.title,
    address: row.address,
    lat: row.lat,
    lng: row.lng,
    type: row.type,
    map_type: row.map_type,
    expires_at: row.expires_at,
    photo_url: row.photo_url,
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
  emitToGroup(groupId, 'mapa_tatico_point_created', { point: serializePointRow(point) });
}

function emitPointUpdated(groupId, point) {
  emitToGroup(groupId, 'mapa_tatico_point_updated', { point: serializePointRow(point) });
}

function emitPointDeleted(groupId, pointId, mapType) {
  emitToGroup(groupId, 'mapa_tatico_point_deleted', {
    point_id: pointId,
    map_type: mapType,
  });
}

function emitCommentAdded(groupId, pointId, comment) {
  emitToGroup(groupId, 'mapa_tatico_comment_added', {
    point_id: pointId,
    comment: serializeCommentRow(comment),
  });
}

function emitMemberJoined(groupId, member) {
  emitToGroup(groupId, 'mapa_tatico_member_joined', { member });
}

function emitMemberLocationUpdated(groupId, location) {
  emitToGroup(groupId, 'mapa_tatico_location_updated', { location });
}

module.exports = {
  emitPointCreated,
  emitPointUpdated,
  emitPointDeleted,
  emitCommentAdded,
  emitMemberJoined,
  emitMemberLocationUpdated,
};
