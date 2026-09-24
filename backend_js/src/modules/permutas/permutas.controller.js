// /src/modules/permutas/permutas.controller.js

const permutasService = require('./permutas.service');
const previewService = require('./permutas-preview.service');
const metricasService = require('./permutas-metricas.service');

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
        (req) => permutasService.findMatchesForPolicial(req.user.id),
        200
    ),
    previewSimulacao: handleRequest(
        (req) => previewService.simular(req.body),
        200
    ),
    publicStats: handleRequest(
        () => previewService.getPublicStats(),
        200
    ),
    getMetricas: handleRequest(
        (req) => metricasService.getUnifiedMetricsForPolicial(req.user.id),
        200
    ),
};