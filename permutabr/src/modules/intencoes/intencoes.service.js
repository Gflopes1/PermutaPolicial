// /src/modules/intencoes/intencoes.service.js

const intencoesRepository = require('./intencoes.repository');

class IntencoesService {
  async getByPolicialId(policialId) {
    // A lógica é simples, apenas repassa a chamada para o repositório
    const intencoes = await intencoesRepository.findByPolicialId(policialId);
    return intencoes;
  }

  async updateByPolicialId(policialId, intencoes) {
    // Delega a operação transacional complexa para o repositório
    await intencoesRepository.replaceAll(policialId, intencoes);
    return { message: 'Intenções atualizadas com sucesso.' };
  }

  async deleteByPolicialId(policialId) {
    await intencoesRepository.deleteAll(policialId);
    return { message: 'Intenções excluídas com sucesso.' };
  }
}

module.exports = new IntencoesService();