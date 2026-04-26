// /src/modules/notificacoes/notificacoes.controller.js

const notificacoesService = require('./notificacoes.service');
const logger = require('../../core/utils/logger');

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
    (req) => {
      // ✅ LOG: Verifica o que está chegando no body (apenas em desenvolvimento)
      logger.debug('Controller criarSolicitacaoContato recebeu', {
        origem: req.body.origem,
        tipoPermuta: req.body.tipo_permuta
      });
      return notificacoesService.criarSolicitacaoContato(
        req.user.id, 
        req.body.destinatario_id,
        req.body.origem || null,
        req.body.tipo_permuta || null
      );
    },
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

  countNaoLidas: async (req, res, next) => {
    try {
      const count = await notificacoesService.countNaoLidas(req.user.id);
      // Retorna apenas o número diretamente, sem wrapper, para otimizar o tamanho da resposta
      res.status(200).json({ count: count.count });
    } catch (error) {
      next(error);
    }
  },

  delete: handleRequest(
    (req) => notificacoesService.delete(req.params.id, req.user.id),
    200
  ),
};

