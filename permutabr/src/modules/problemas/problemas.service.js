// /src/modules/problemas/problemas.service.js

const problemasRepository = require('./problemas.repository');

class ProblemasService {
  async criarRelato(relatoData) {
    const relatoId = await problemasRepository.criarRelato(relatoData);
    return { id: relatoId, success: true };
  }

  async buscarRelatos(filtros = {}) {
    const relatos = await problemasRepository.buscarRelatos(filtros);
    const total = await problemasRepository.contarRelatos(filtros);
    return {
      relatos,
      total,
      page: filtros.page || 1,
      perPage: filtros.perPage || 20,
      totalPages: Math.ceil(total / (filtros.perPage || 20)),
    };
  }

  async buscarRelatoPorId(id) {
    const relato = await problemasRepository.buscarRelatoPorId(id);
    if (!relato) {
      throw new Error('Relato não encontrado');
    }
    return relato;
  }

  async atualizarStatus(id, status, resolvidoPor = null, resolucao = null) {
    const relato = await problemasRepository.buscarRelatoPorId(id);
    if (!relato) {
      throw new Error('Relato não encontrado');
    }

    await problemasRepository.atualizarStatus(id, status, resolvidoPor, resolucao);
    return { success: true };
  }

  async getEstatisticas(dataInicio = null, dataFim = null) {
    const estatisticas = await problemasRepository.getEstatisticas(dataInicio, dataFim);
    const porPagina = await problemasRepository.getRelatosPorPagina(dataInicio, dataFim);
    return {
      ...estatisticas,
      porPagina,
    };
  }
}

module.exports = new ProblemasService();
