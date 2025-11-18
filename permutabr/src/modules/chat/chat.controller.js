// /src/modules/chat/chat.controller.js

const chatService = require('./chat.service');

const handleRequest = (servicePromise, successStatus = 200) => async (req, res, next) => {
  try {
    const result = await servicePromise(req);
    res.status(successStatus).json({ status: 'success', data: result });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getConversas: handleRequest((req) => chatService.getConversas(req)),
  getConversa: handleRequest((req) => chatService.getConversa(req)),
  getMensagens: handleRequest((req) => chatService.getMensagens(req)),
  createMensagem: handleRequest((req) => chatService.createMensagem(req), 201),
  iniciarConversa: handleRequest((req) => chatService.iniciarConversa(req), 201),
  marcarComoLidas: handleRequest((req) => chatService.marcarComoLidas(req)),
  getMensagensNaoLidas: handleRequest((req) => chatService.getMensagensNaoLidas(req)),
};




