const permutasInteligentesService = require('./permutas-inteligentes.service');

const handleRequest = (servicePromise, successStatus) => async (req, res, next) => {
  try {
    const result = await servicePromise(req);
    res.status(successStatus).json({ status: 'success', data: result });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  findMatches: handleRequest(
    (req) =>
      permutasInteligentesService.computeMatchesForPolicial(req.user.id, {
        forceRefresh: req.query.refresh === '1',
      }),
    200
  ),

  getSummary: handleRequest(
    (req) => permutasInteligentesService.getSummaryForPolicial(req.user.id),
    200
  ),

  getAdminGraph: handleRequest(
    (req) => permutasInteligentesService.getAdminGraphData(req.query.rebuild === 'true'),
    200
  ),

  getAdminGraphPoster: handleRequest(
    (req) =>
      permutasInteligentesService.getAdminGraphPosterData(req.query.rebuild === 'true', {
        estado: req.query.estado || null,
        forcaId: req.query.forca_id || null,
        cityLimit: permutasInteligentesService.parsePosterCityLimit(req.query.city_limit),
      }),
    200
  ),

  rebuildAdminGraph: handleRequest(
    () => permutasInteligentesService.rebuildAdminGraphSync(),
    200
  ),
};
