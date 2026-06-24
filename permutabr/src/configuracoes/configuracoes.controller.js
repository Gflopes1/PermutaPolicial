// /src/modules/configuracoes/configuracoes.controller.js

const configuracoesService = require('./configuracoes.service');
const ApiError = require('../../core/utils/ApiError');

module.exports = {
  getNotaAtualizacao: async (req, res, next) => {
    try {
      const result = await configuracoesService.getNotaAtualizacao();
      res.status(200).json({ status: 'success', data: result });
    } catch (error) {
      next(error);
    }
  },
};

