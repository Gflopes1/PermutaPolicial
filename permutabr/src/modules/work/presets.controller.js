// /src/modules/work/presets.controller.js

const presetsService = require('./presets.service');

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
  // GET /api/presets
  getPresets: handleRequest(
    (req) => presetsService.getPresets(req.user.id),
    200
  ),

  // GET /api/presets/:id
  getPresetById: handleRequest(
    (req) => presetsService.getPresetById(req.user.id, parseInt(req.params.id)),
    200
  ),

  // POST /api/presets
  createPreset: handleRequest(
    (req) => presetsService.createPreset(req.user.id, req.body),
    201
  ),

  // PUT /api/presets/:id
  updatePreset: handleRequest(
    (req) => presetsService.updatePreset(
      req.user.id,
      parseInt(req.params.id),
      req.body
    ),
    200
  ),

  // DELETE /api/presets/:id
  deletePreset: handleRequest(
    (req) => presetsService.deletePreset(req.user.id, parseInt(req.params.id)),
    200
  ),
};


