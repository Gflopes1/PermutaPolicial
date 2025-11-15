// /src/modules/forum/forum.controller.js

const forumService = require('./forum.service');

const handleRequest = (servicePromise, successStatus = 200) => async (req, res, next) => {
  try {
    const result = await servicePromise(req);
    res.status(successStatus).json({ status: 'success', data: result });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getCategorias: handleRequest((req) => forumService.getCategorias(req)),
  getTopicos: handleRequest((req) => forumService.getTopicos(req)),
  getTopico: handleRequest((req) => forumService.getTopico(req)),
  createTopico: handleRequest((req) => forumService.createTopico(req), 201),
  updateTopico: handleRequest((req) => forumService.updateTopico(req)),
  deleteTopico: handleRequest((req) => forumService.deleteTopico(req)),
  searchTopicos: handleRequest((req) => forumService.searchTopicos(req)),
  getRespostas: handleRequest((req) => forumService.getRespostas(req)),
  createResposta: handleRequest((req) => forumService.createResposta(req), 201),
  updateResposta: handleRequest((req) => forumService.updateResposta(req)),
  deleteResposta: handleRequest((req) => forumService.deleteResposta(req)),
  toggleReacao: handleRequest((req) => forumService.toggleReacao(req)),
  getReacoes: handleRequest((req) => forumService.getReacoes(req)),
  
  // Moderação
  aprovarTopico: handleRequest((req) => forumService.aprovarTopico(req)),
  rejeitarTopico: handleRequest((req) => forumService.rejeitarTopico(req)),
  toggleFixarTopico: handleRequest((req) => forumService.toggleFixarTopico(req)),
  toggleBloquearTopico: handleRequest((req) => forumService.toggleBloquearTopico(req)),
  aprovarResposta: handleRequest((req) => forumService.aprovarResposta(req)),
  rejeitarResposta: handleRequest((req) => forumService.rejeitarResposta(req)),
  getTopicosPendentes: handleRequest((req) => forumService.getTopicosPendentes(req)),
  getRespostasPendentes: handleRequest((req) => forumService.getRespostasPendentes(req)),
};

