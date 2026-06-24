// /src/modules/mapa-tatico/mapa-tatico.routes.js

const express = require('express');
const multer = require('multer');
const path = require('path');
const { celebrate } = require('celebrate');
const mapaTaticoController = require('./mapa-tatico.controller');
const mapaTaticoValidation = require('./mapa-tatico.validation');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const mapaTaticoMiddleware = require('./middlewares/mapa-tatico.middleware');
const rateLimit = require('express-rate-limit');

const router = express.Router();

const reportLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000,
  max: 10,
  message: { status: 'error', message: 'Muitas denúncias enviadas. Tente novamente mais tarde.' },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => `${req.user?.id || 'anon'}:${req.params.id || 'point'}`,
});

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 12 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowedExt = ['jpeg', 'jpg', 'png', 'webp', 'heic', 'heif'];
    const ext = path.extname(file.originalname || '').toLowerCase().replace(/^\./, '');
    const extOk = allowedExt.includes(ext);
    const mime = (file.mimetype || '').toLowerCase();
    const mimeOk =
      mime.startsWith('image/') ||
      allowedExt.some((t) => mime.includes(t));
    // Flutter web costuma enviar bytes sem MIME/extensão corretos; magic bytes validam depois.
    const genericBinary = mime === 'application/octet-stream' || mime === '';

    if (extOk || mimeOk || genericBinary) {
      return cb(null, true);
    }
    cb(new Error('Apenas imagens são permitidas (JPEG, PNG, WEBP, HEIC)'));
  },
});

router.use(authMiddleware);

router.get('/status', mapaTaticoController.getStatus);

router.get(
  '/geocode/search',
  celebrate({ query: mapaTaticoValidation.queryGeocodeSearch }),
  mapaTaticoController.geocodeSearch
);

router.get(
  '/geocode/reverse',
  celebrate({ query: mapaTaticoValidation.queryGeocodeReverse }),
  mapaTaticoController.geocodeReverse
);

router.get('/reports', mapaTaticoController.listReports);

router.patch(
  '/reports/:reportId',
  celebrate({ params: mapaTaticoValidation.paramsReportId, body: mapaTaticoValidation.reviewReport }),
  mapaTaticoController.reviewReport
);

// ========== GRUPOS ==========
router.post('/groups', celebrate({ body: mapaTaticoValidation.createGroup }), mapaTaticoController.createGroup);
router.get('/groups', mapaTaticoController.getGroups);
router.get('/groups/invites/pending', mapaTaticoController.getPendingInvites);
router.post(
  '/groups/invites/:inviteId/accept',
  celebrate({ params: mapaTaticoValidation.paramsInviteId }),
  mapaTaticoController.acceptInvite
);
router.post(
  '/groups/invites/:inviteId/reject',
  celebrate({ params: mapaTaticoValidation.paramsInviteId }),
  mapaTaticoController.rejectInvite
);

router.get(
  '/groups/:id/members',
  celebrate({ params: mapaTaticoValidation.paramsGroupId }),
  mapaTaticoMiddleware.requireGroupMember,
  mapaTaticoController.getGroupMembers
);

router.post(
  '/groups/:id/switch',
  celebrate({ params: mapaTaticoValidation.paramsGroupId }),
  mapaTaticoMiddleware.requireGroupMember,
  mapaTaticoController.switchGroup
);

router.post(
  '/groups/:id/leave',
  celebrate({ params: mapaTaticoValidation.paramsGroupId }),
  mapaTaticoMiddleware.requireGroupMember,
  mapaTaticoController.leaveGroup
);

router.put(
  '/groups/:id/location',
  celebrate({ params: mapaTaticoValidation.paramsGroupId, body: mapaTaticoValidation.updateMemberLocation }),
  mapaTaticoMiddleware.requireGroupMember,
  mapaTaticoController.updateMemberLocation
);

router.get(
  '/groups/:id/locations',
  celebrate({ params: mapaTaticoValidation.paramsGroupId }),
  mapaTaticoMiddleware.requireGroupMember,
  mapaTaticoController.getMemberLocations
);

router.delete(
  '/groups/:id/location',
  celebrate({ params: mapaTaticoValidation.paramsGroupId }),
  mapaTaticoMiddleware.requireGroupMember,
  mapaTaticoController.stopSharingLocation
);

router.get(
  '/groups/:id/intelligence',
  celebrate({ params: mapaTaticoValidation.paramsGroupId, query: mapaTaticoValidation.queryIntelligence }),
  mapaTaticoMiddleware.requireGroupMember,
  mapaTaticoController.getIntelligence
);

router.post(
  '/groups/:id/invite',
  celebrate({ params: mapaTaticoValidation.paramsGroupId, body: mapaTaticoValidation.inviteGroup }),
  mapaTaticoMiddleware.requireGroupMember,
  mapaTaticoMiddleware.requireModeratorOrAdmin,
  mapaTaticoController.inviteToGroup
);

router.patch(
  '/groups/:id/nome-de-guerra',
  celebrate({ params: mapaTaticoValidation.paramsGroupId, body: mapaTaticoValidation.nomeDeGuerra }),
  mapaTaticoMiddleware.requireGroupMember,
  mapaTaticoController.updateNomeDeGuerra
);

router.patch(
  '/groups/:groupId/members/:userId/nome-de-guerra',
  celebrate({ params: mapaTaticoValidation.paramsGroupIdUserId, body: mapaTaticoValidation.nomeDeGuerra }),
  (req, res, next) => { req.params.id = req.params.groupId; next(); },
  mapaTaticoMiddleware.requireGroupMember,
  mapaTaticoController.updateMemberNomeDeGuerra
);

router.patch(
  '/groups/:groupId/members/:userId/mute',
  celebrate({ params: mapaTaticoValidation.paramsGroupIdUserId, body: mapaTaticoValidation.muteMember }),
  (req, res, next) => { req.params.id = req.params.groupId; next(); },
  mapaTaticoMiddleware.requireGroupMember,
  mapaTaticoMiddleware.requireModeratorOrAdmin,
  mapaTaticoController.muteMember
);

router.delete(
  '/groups/:groupId/members/:userId',
  celebrate({ params: mapaTaticoValidation.paramsGroupIdUserId }),
  (req, res, next) => { req.params.id = req.params.groupId; next(); },
  mapaTaticoMiddleware.requireGroupMember,
  mapaTaticoMiddleware.requireModeratorOrAdmin,
  mapaTaticoController.removeMember
);

router.patch(
  '/groups/:groupId/members/:userId/promote',
  celebrate({ params: mapaTaticoValidation.paramsGroupIdUserId }),
  (req, res, next) => { req.params.id = req.params.groupId; next(); },
  mapaTaticoMiddleware.requireGroupMember,
  mapaTaticoMiddleware.requireModeratorOrAdmin,
  mapaTaticoController.promoteMember
);

// ========== PONTOS ==========
router.post(
  '/points',
  upload.single('photo'),
  mapaTaticoMiddleware.validateUploadedImage,
  celebrate({ body: mapaTaticoValidation.createPoint }),
  mapaTaticoController.createPoint
);

router.get(
  '/points',
  celebrate({ query: mapaTaticoValidation.queryPoints }),
  mapaTaticoController.getPoints
);

router.get(
  '/points/:id',
  celebrate({ params: mapaTaticoValidation.paramsPointId }),
  mapaTaticoMiddleware.requirePointAccess,
  mapaTaticoController.getPoint
);

const updatePointMiddleware = [
  upload.single('photo'),
  mapaTaticoMiddleware.validateUploadedImage,
  celebrate({ params: mapaTaticoValidation.paramsPointId, body: mapaTaticoValidation.updatePoint }),
  mapaTaticoMiddleware.requirePointAccess,
  mapaTaticoMiddleware.requirePointModeratorOrAuthor,
  mapaTaticoController.updatePoint,
];
router.patch('/points/:id', ...updatePointMiddleware);
router.put('/points/:id', ...updatePointMiddleware);

router.delete(
  '/points/:id',
  celebrate({ params: mapaTaticoValidation.paramsPointId }),
  mapaTaticoMiddleware.requirePointAccess,
  mapaTaticoMiddleware.requirePointModeratorOrAuthor,
  mapaTaticoController.deletePoint
);

// ========== COMENTÁRIOS ==========
router.get(
  '/points/:id/comments',
  celebrate({
    params: mapaTaticoValidation.paramsPointId,
    query: mapaTaticoValidation.queryPagination,
  }),
  mapaTaticoMiddleware.requirePointAccess,
  mapaTaticoController.getComments
);

router.post(
  '/points/:id/comments',
  celebrate({ params: mapaTaticoValidation.paramsPointId, body: mapaTaticoValidation.createComment }),
  mapaTaticoMiddleware.requirePointAccess,
  (req, res, next) => {
    req.groupMember = req.pointMember;
    next();
  },
  mapaTaticoMiddleware.requireNotMuted,
  mapaTaticoController.createComment
);

// ========== DENÚNCIAS ==========
router.post(
  '/points/:id/report',
  reportLimiter,
  celebrate({ params: mapaTaticoValidation.paramsPointId, body: mapaTaticoValidation.reportPoint }),
  mapaTaticoMiddleware.requirePointAccess,
  mapaTaticoController.reportPoint
);

// ========== VISITAS ==========
router.post(
  '/points/:id/visit',
  celebrate({ params: mapaTaticoValidation.paramsPointId }),
  mapaTaticoMiddleware.requirePointAccess,
  mapaTaticoController.createVisit
);

router.get(
  '/points/:id/visits',
  celebrate({ params: mapaTaticoValidation.paramsPointId, query: mapaTaticoValidation.queryLastDays }),
  mapaTaticoMiddleware.requirePointAccess,
  mapaTaticoController.getVisits
);

// ========== AUDITORIA ==========
router.get(
  '/points/:id/audit',
  celebrate({ params: mapaTaticoValidation.paramsPointId }),
  mapaTaticoMiddleware.requirePointAccess,
  mapaTaticoMiddleware.requireAuditAccess,
  mapaTaticoController.getAudit
);

module.exports = router;
