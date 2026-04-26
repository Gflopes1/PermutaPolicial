// /src/modules/work/work.controller.js

const workService = require('./work.service');
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
  // GET /api/work/month
  getMonth: handleRequest(
    (req) => workService.getMonthDays(
      req.user.id,
      parseInt(req.query.month),
      parseInt(req.query.year)
    ),
    200
  ),

  // POST /api/work/day
  upsertDay: handleRequest(
    async (req) => {
      const { data, intervals, ...dayData } = req.body;
      return await workService.upsertDay(
        req.user.id,
        data,
        dayData,
        intervals || []
      );
    },
    200
  ),

  // DELETE /api/work/day/:id
  deleteDay: handleRequest(
    (req) => workService.deleteDay(req.user.id, parseInt(req.params.id)),
    200
  ),

  // POST /api/work/apply-preset
  applyPreset: handleRequest(
    async (req) => {
      const { dates, preset_id } = req.body;
      const preset = await presetsService.getPresetById(req.user.id, preset_id);
      
      const presetData = {
        duracao: preset.duracao,
        tipo: preset.tipo,
        flag_abatimento: preset.flag_abatimento,
        etapa_rule_override: preset.etapa_rule_override,
        // Intervalos removidos - não são mais necessários, apenas duracao é usada
      };

      return await workService.applyPresetToDays(
        req.user.id,
        dates,
        preset_id,
        presetData
      );
    },
    200
  ),

  // GET /api/work/stats
  getStats: handleRequest(
    (req) => workService.getMonthStats(
      req.user.id,
      parseInt(req.query.month),
      parseInt(req.query.year)
    ),
    200
  ),
};


