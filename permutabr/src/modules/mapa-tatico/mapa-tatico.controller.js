// /src/modules/mapa-tatico/mapa-tatico.controller.js

const mapaTaticoService = require('./mapa-tatico.service');

const handleRequest = (serviceFn, successStatus = 200) => async (req, res, next) => {
  try {
    const result = await serviceFn(req);
    res.status(successStatus).json({ status: 'success', data: result });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getStatus: handleRequest(mapaTaticoService.getStatus),
  createGroup: handleRequest(mapaTaticoService.createGroup, 201),
  getGroups: handleRequest(mapaTaticoService.getGroups),
  switchGroup: handleRequest(mapaTaticoService.switchGroup),
  leaveGroup: handleRequest(mapaTaticoService.leaveGroup),
  inviteToGroup: handleRequest(mapaTaticoService.inviteToGroup, 201),
  getPendingInvites: handleRequest(mapaTaticoService.getPendingInvites),
  acceptInvite: handleRequest(mapaTaticoService.acceptInvite),
  rejectInvite: handleRequest(mapaTaticoService.rejectInvite),
  getGroupMembers: handleRequest(mapaTaticoService.getGroupMembers),
  updateNomeDeGuerra: handleRequest(mapaTaticoService.updateNomeDeGuerra),
  updateMemberNomeDeGuerra: handleRequest(mapaTaticoService.updateMemberNomeDeGuerra),
  muteMember: handleRequest(mapaTaticoService.muteMember),
  removeMember: handleRequest(mapaTaticoService.removeMember),
  promoteMember: handleRequest(mapaTaticoService.promoteMember),
  createPoint: handleRequest(mapaTaticoService.createPoint, 201),
  getPoints: handleRequest(mapaTaticoService.getPoints),
  getPoint: handleRequest(mapaTaticoService.getPoint),
  updatePoint: handleRequest(mapaTaticoService.updatePoint),
  deletePoint: handleRequest(mapaTaticoService.deletePoint),
  createComment: handleRequest(mapaTaticoService.createComment, 201),
  getComments: handleRequest(mapaTaticoService.getComments),
  reportPoint: handleRequest(mapaTaticoService.reportPoint, 201),
  createVisit: handleRequest(mapaTaticoService.createVisit, 201),
  getVisits: handleRequest(mapaTaticoService.getVisits),
  getAudit: handleRequest(mapaTaticoService.getAudit),
  geocodeSearch: handleRequest(mapaTaticoService.geocodeSearch),
  geocodeReverse: handleRequest(mapaTaticoService.geocodeReverse),
  updateMemberLocation: handleRequest(mapaTaticoService.updateMemberLocation),
  getMemberLocations: handleRequest(mapaTaticoService.getMemberLocations),
  stopSharingLocation: handleRequest(mapaTaticoService.stopSharingLocation),
  getIntelligence: handleRequest(mapaTaticoService.getIntelligence),
  listReports: handleRequest(mapaTaticoService.listReports),
  reviewReport: handleRequest(mapaTaticoService.reviewReport),
};
