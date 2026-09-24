// /src/modules/configuracoes/configuracoes.service.js

const configuracoesRepository = require('./configuracoes.repository');

class ConfiguracoesService {
  async getAppConfig() {
    return configuracoesRepository.getAppConfig();
  }

  async getNotaAtualizacao() {
    return configuracoesRepository.getNotaAtualizacao();
  }

  async getApoio() {
    return configuracoesRepository.getApoio();
  }
}

module.exports = new ConfiguracoesService();

