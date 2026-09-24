const mapaTaticoAdminService = require('./mapa-tatico-admin.service');

const handleRequest = (serviceFn, successStatus = 200) => async (req, res, next) => {
  try {
    const result = await serviceFn(req);
    res.status(successStatus).json({ status: 'success', data: result });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  listGroups: handleRequest(mapaTaticoAdminService.listGroups),
  getGroupDetail: handleRequest(mapaTaticoAdminService.getGroupDetail),
  removePoint: handleRequest(mapaTaticoAdminService.removePoint),
  removeMember: handleRequest(mapaTaticoAdminService.removeMember, 200),
};
