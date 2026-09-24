const pushService = require('./push.service');

const handleRequest = (serviceFn, successStatus = 200) => async (req, res, next) => {
  try {
    const result = await serviceFn(req);
    res.status(successStatus).json({ status: 'success', data: result });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register: handleRequest(pushService.registerDeviceToken, 201),
  unregister: handleRequest(pushService.unregisterDeviceToken),
  status: handleRequest(pushService.getPushStatus),
  test: handleRequest(pushService.testPush),
};
