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

  async renewByPolicialId(policialId) {
    const affectedRows = await intencoesRepository.renewAll(policialId);
    return {
      message: affectedRows > 0
        ? 'Intenções renovadas com sucesso.'
        : 'Nenhuma intenção encontrada para renovar.',
      affectedRows,
    };
  }

  async markPermutaConcluida(policialId) {
    const result = await intencoesRepository.markPermutaConcluida(policialId);
    return {
      message: 'Obrigado pelo retorno! Registramos que você conseguiu permutar.',
      quantidade_intencoes: result.quantidade,
    };
  }
}

module.exports = new IntencoesService();
