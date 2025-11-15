// /src/modules/intencoes/intencoes.controller.js

const intencoesService = require('./intencoes.service');

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
  getMyIntentions: handleRequest(
    (req) => intencoesService.getByPolicialId(req.user.id),
    200
  ),

  updateMyIntentions: handleRequest(
    // Passamos o policialId e o array de intenções para o serviço
    (req) => intencoesService.updateByPolicialId(req.user.id, req.body.intencoes),
    200
  ),

  deleteMyIntentions: handleRequest(
    (req) => intencoesService.deleteByPolicialId(req.user.id),
    200
  ),
};