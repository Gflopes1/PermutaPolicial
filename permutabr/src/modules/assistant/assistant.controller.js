// /src/modules/assistant/assistant.controller.js

const assistantService = require('./assistant.service');

const handleRequest = (servicePromise, successStatus = 200) => async (req, res, next) => {
  try {
    const result = await servicePromise(req);
    res.status(successStatus).json({ status: 'success', data: result });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  consultar: handleRequest(async (req) => {
    const { texto, sessionId } = req.body;
    const policialId = req.user?.id;
    
    if (!policialId) {
      throw new Error('Usuário não autenticado');
    }
    
    return await assistantService.consultar(policialId, texto, sessionId);
  }),

  gerarBoletim: handleRequest(async (req) => {
    const dados = req.body;
    return await assistantService.gerarBoletim(dados);
  }),
};

