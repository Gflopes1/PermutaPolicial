// /src/modules/notificacoes/notificacoes.controller.js

const notificacoesService = require('./notificacoes.service');

const handleRequest = (servicePromise, successStatus = 200) => async (req, res, next) => {
  try {
    const result = await servicePromise(req);
    res.status(successStatus).json({ status: 'success', data: result });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getNotificacoes: handleRequest(
    (req) => notificacoesService.getNotificacoes(req.user.id),
    200
  ),

  criarSolicitacaoContato: handleRequest(
    (req) => notificacoesService.criarSolicitacaoContato(req.user.id, req.body.destinatario_id),
    201
  ),

  responderSolicitacaoContato: handleRequest(
    (req) => notificacoesService.responderSolicitacaoContato(
      req.params.id,
      req.user.id,
      req.body.aceitar === true
    ),
    200
  ),

  marcarComoLida: handleRequest(
    (req) => notificacoesService.marcarComoLida(req.params.id, req.user.id),
    200
  ),

  marcarTodasComoLidas: handleRequest(
    (req) => notificacoesService.marcarTodasComoLidas(req.user.id),
    200
  ),

  countNaoLidas: handleRequest(
    (req) => notificacoesService.countNaoLidas(req.user.id),
    200
  ),

  delete: handleRequest(
    (req) => notificacoesService.delete(req.params.id, req.user.id),
    200
  ),
};

