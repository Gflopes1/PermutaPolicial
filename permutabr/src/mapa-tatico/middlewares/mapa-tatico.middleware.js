// /src/modules/mapa-tatico/middlewares/mapa-tatico.middleware.js



const ApiError = require('../../../core/utils/ApiError');

const mapaTaticoRepository = require('../mapa-tatico.repository');

const { validateImageMagicBytes } = require('../mapa-tatico-security.utils');



/**

 * Admin do sistema (embaixador ou moderador global).

 * req.user é revalidado do banco a cada request via auth.middleware —

 * revogação de privilégios entra em vigor imediatamente, independente do TTL do JWT.

 */

function isSystemAdmin(req) {

  return req.user && (

    req.user.embaixador === 1 || req.user.is_moderator === 1 ||

    req.user.embaixador === true || req.user.is_moderator === true

  );

}



async function requireGroupMember(req, res, next) {

  const groupId = req.params.id || req.params.groupId || req.body.group_id;

  if (!groupId) {

    return next(new ApiError(400, 'ID do grupo é obrigatório.'));

  }

  const member = await mapaTaticoRepository.findMember(parseInt(groupId), req.user.id);

  if (!member) {

    return next(new ApiError(403, 'Você não é membro deste grupo.'));

  }

  req.groupMember = member;

  req.groupId = parseInt(groupId);

  next();

}



async function requireModeratorOrAdmin(req, res, next) {

  if (isSystemAdmin(req)) return next();

  const member = req.groupMember;

  if (!member || member.role !== 'MODERATOR') {

    return next(new ApiError(403, 'Apenas moderadores do grupo ou moderadores gerais do site podem realizar esta ação.'));

  }

  next();

}



function requireNotMuted(req, res, next) {

  const member = req.groupMember || req.pointMember;

  if (member && member.is_muted) {

    return next(new ApiError(403, 'Você está mutado neste grupo e não pode criar pontos ou comentários.'));

  }

  next();

}



async function requirePointAccess(req, res, next) {

  const pointId = req.params.id || req.params.pointId;

  if (!pointId) {

    return next(new ApiError(400, 'ID do ponto é obrigatório.'));

  }

  const point = await mapaTaticoRepository.findPointById(parseInt(pointId));

  if (!point) {

    return next(new ApiError(404, 'Ponto não encontrado.'));

  }

  const member = await mapaTaticoRepository.findMember(point.group_id, req.user.id);

  if (!member && !isSystemAdmin(req)) {

    return next(new ApiError(403, 'Você não tem acesso a este ponto.'));

  }

  req.point = point;

  req.pointMember = member;

  next();

}



function requirePointModeratorOrAuthor(req, res, next) {

  if (isSystemAdmin(req)) return next();

  const point = req.point;

  const member = req.pointMember;

  if (!member) return next(new ApiError(403, 'Acesso negado.'));

  const isAuthor = point.creator_id === req.user.id;

  const isModerator = member.role === 'MODERATOR';

  if (!isAuthor && !isModerator) {

    return next(new ApiError(403, 'Apenas o criador ou moderadores podem editar/excluir este ponto.'));

  }

  next();

}



/** Logs de auditoria: apenas administradores do sistema (não moderadores de grupo). */

async function requireAuditAccess(req, res, next) {

  if (!isSystemAdmin(req)) {

    return next(new ApiError(403, 'Apenas administradores do sistema podem visualizar a auditoria.'));

  }

  next();

}



/** Valida magic bytes após upload multer (memória). */

function validateUploadedImage(req, res, next) {

  if (!req.file || !req.file.buffer) return next();

  try {

    validateImageMagicBytes(req.file.buffer);

    next();

  } catch (err) {

    next(err);

  }

}



module.exports = {

  requireGroupMember,

  requireModeratorOrAdmin,

  requireNotMuted,

  requirePointAccess,

  requirePointModeratorOrAuthor,

  requireAuditAccess,

  validateUploadedImage,

  isSystemAdmin,

};


