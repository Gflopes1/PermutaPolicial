const express = require('express');
const { celebrate } = require('celebrate');
const authMiddleware = require('../../../core/middlewares/auth.middleware');
const embaixadorMiddleware = require('../../../core/middlewares/embaixador.middleware');
const mapaTaticoAdminController = require('./mapa-tatico-admin.controller');
const mapaTaticoValidation = require('../mapa-tatico.validation');

const router = express.Router();

router.use(authMiddleware, embaixadorMiddleware);

router.get(
  '/groups',
  celebrate({ query: mapaTaticoValidation.queryAdminGroups }),
  mapaTaticoAdminController.listGroups
);

router.get(
  '/groups/:id',
  celebrate({
    params: mapaTaticoValidation.paramsGroupId,
    query: mapaTaticoValidation.queryAdminGroupDetail,
  }),
  mapaTaticoAdminController.getGroupDetail
);

router.delete(
  '/groups/:id/points/:pointId',
  celebrate({ params: mapaTaticoValidation.paramsAdminGroupPoint }),
  mapaTaticoAdminController.removePoint
);

router.delete(
  '/groups/:id/members/:userId',
  celebrate({
    params: mapaTaticoValidation.paramsAdminGroupMember,
    body: mapaTaticoValidation.adminRemoveMember,
  }),
  mapaTaticoAdminController.removeMember
);

module.exports = router;
