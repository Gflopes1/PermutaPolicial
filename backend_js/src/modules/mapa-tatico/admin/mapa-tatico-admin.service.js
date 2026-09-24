const mapaTaticoAdminRepository = require('./mapa-tatico-admin.repository');
const mapaTaticoRepository = require('../mapa-tatico.repository');
const mapaTaticoService = require('../mapa-tatico.service');
const ApiError = require('../../../core/utils/ApiError');
const { safeLimit, safeOffset } = require('../mapa-tatico-security.utils');

async function listGroups(req) {
  const page = parseInt(req.query.page, 10) || 1;
  const limit = safeLimit(req.query.limit, 20, 100);
  const offset = safeOffset((page - 1) * limit);
  const search = req.query.search ? String(req.query.search).trim() : null;

  await mapaTaticoAdminRepository.createAdminActionLog(req.user.id, 'VIEW_GROUP_LIST');
  const groups = await mapaTaticoAdminRepository.findGroupsForAdmin(search, limit, offset);
  return { groups, page, limit };
}

async function getGroupDetail(req) {
  const groupId = parseInt(req.params.id, 10);
  const detail = await mapaTaticoAdminRepository.findGroupDetailForAdmin(groupId);
  if (!detail) throw new ApiError(404, 'Grupo não encontrado.');

  const mapType = req.query.map_type || null;
  const type = req.query.type || null;
  const limit = safeLimit(req.query.limit, 50, 100);
  const offset = safeOffset(req.query.offset);

  const points = await mapaTaticoAdminRepository.findPointsByGroupForAdmin(
    groupId,
    mapType,
    type,
    limit,
    offset
  );

  await mapaTaticoAdminRepository.createAdminActionLog(
    req.user.id,
    'VIEW_GROUP_DETAIL',
    groupId
  );

  return { ...detail, points };
}

async function removePoint(req) {
  const groupId = parseInt(req.params.id, 10);
  const pointId = parseInt(req.params.pointId, 10);
  const point = await mapaTaticoRepository.findPointById(pointId);
  if (!point || point.group_id !== groupId) {
    throw new ApiError(404, 'Ponto não encontrado neste grupo.');
  }

  req.point = point;
  req.user.id = req.user.id;
  await mapaTaticoService.deletePoint(req);

  await mapaTaticoAdminRepository.createAdminActionLog(
    req.user.id,
    'REMOVE_POINT',
    groupId,
    pointId
  );

  return { success: true };
}

async function removeMember(req) {
  const groupId = parseInt(req.params.id, 10);
  const userId = parseInt(req.params.userId, 10);
  const motivo = req.body?.motivo;
  if (!motivo || String(motivo).trim().length < 10) {
    throw new ApiError(400, 'motivo é obrigatório (mínimo 10 caracteres).');
  }

  const group = await mapaTaticoRepository.findGroupById(groupId);
  if (!group || group.is_global) throw new ApiError(404, 'Grupo não encontrado.');

  const removed = await mapaTaticoRepository.removeMember(groupId, userId);
  if (!removed) throw new ApiError(404, 'Membro não encontrado no grupo.');

  await mapaTaticoAdminRepository.createAdminActionLog(
    req.user.id,
    'REMOVE_MEMBER',
    groupId,
    userId,
    String(motivo).trim()
  );

  return { success: true, message: 'Membro removido.' };
}

module.exports = {
  listGroups,
  getGroupDetail,
  removePoint,
  removeMember,
};
