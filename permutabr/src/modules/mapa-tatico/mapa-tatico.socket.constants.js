// Constantes de salas Socket.IO — sem imports para evitar dependência circular com config/socket.js

const ROOM_PREFIX = 'mapa_tatico_group_';

function groupRoom(groupId) {
  return `${ROOM_PREFIX}${groupId}`;
}

module.exports = { ROOM_PREFIX, groupRoom };
