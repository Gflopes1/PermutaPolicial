// /src/modules/configuracoes/configuracoes.service.js

const configuracoesRepository = require('./configuracoes.repository');

class ConfiguracoesService {
  async getNotaAtualizacao() {
    return configuracoesRepository.getNotaAtualizacao();
  }
}

module.exports = new ConfiguracoesService();

