// /src/modules/policiais/policiais.controller.js

const policiaisService = require('./policiais.service');

const handleRequest = (servicePromise, successStatus) => async (req, res, next) => {
  try {
    const result = await servicePromise(req);
    res.status(successStatus).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getMyProfile: handleRequest(
    (req) => policiaisService.getProfileById(req.user.id),
    200
  ),

  updateMyProfile: handleRequest(
    (req) => policiaisService.updateProfile(req.user.id, req.body),
    200
  ),
};