// /src/modules/analytics/analytics.service.js

const analyticsRepository = require('./analytics.repository');

class AnalyticsService {
  async registrarEvento(eventData) {
    await analyticsRepository.createUserEvent(eventData);
    return { success: true };
  }

  async registrarPageView(pageViewData) {
    const pageViewId = await analyticsRepository.createPageView(pageViewData);
    return { id: pageViewId, success: true };
  }

  async atualizarTempoPermanencia(pageViewId, tempoSegundos) {
    await analyticsRepository.updatePageViewDuration(pageViewId, tempoSegundos);
    return { success: true };
  }

  async criarOuAtualizarSessao(sessionData) {
    const sessionId = await analyticsRepository.createOrUpdateSession(sessionData);
    return { sessionId, success: true };
  }

  async finalizarSessao(sessaoId, duracaoSegundos) {
    await analyticsRepository.endSession(sessaoId, duracaoSegundos);
    return { success: true };
  }

  async getEstatisticasGerais(dataInicio, dataFim) {
    return analyticsRepository.getEstatisticasGerais(dataInicio, dataFim);
  }

  async getPageViewsStats(dataInicio, dataFim) {
    return analyticsRepository.getPageViewsStats(dataInicio, dataFim);
  }

  async getEventosPorTipo(dataInicio, dataFim) {
    return analyticsRepository.getEventosPorTipo(dataInicio, dataFim);
  }

  async getSessoesStats(dataInicio, dataFim) {
    return analyticsRepository.getSessoesStats(dataInicio, dataFim);
  }

  async getAtividadePorHora(dataInicio, dataFim) {
    return analyticsRepository.getAtividadePorHora(dataInicio, dataFim);
  }

  async getCrescimentoUsuarios(dataInicio, dataFim) {
    return analyticsRepository.getCrescimentoUsuarios(dataInicio, dataFim);
  }
}

module.exports = new AnalyticsService();

