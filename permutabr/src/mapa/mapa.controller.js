// /src/modules/mapa/mapa.controller.js

const mapaService = require('./mapa.service');

const handleRequest = (servicePromise, successStatus) => async (req, res, next) => {
  try {
    const result = await servicePromise(req);
    res.status(successStatus).json({ status: 'success', data: result });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getMapData: handleRequest(
    (req) => mapaService.getMapData(req.query),
    200
  ),
  getMunicipioDetails: handleRequest(
    (req) => mapaService.getMunicipioDetails(req.query),
    200
  ),
};