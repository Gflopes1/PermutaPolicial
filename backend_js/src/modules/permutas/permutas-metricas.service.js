// GET /api/permutas/metricas — visão unificada no servidor (Fase G.2)

const permutasService = require('./permutas.service');
const {
  computeMatchesForPolicial,
} = require('../permutas-inteligentes/permutas-inteligentes.service');
const {
  mergeUnifiedMetrics,
  countInteressadosUnified,
  countCompativelDashboardUnified,
  buildLegacyMotorMetrics,
  buildPiMotorMetrics,
} = require('./permutas-metrics');

async function getUnifiedMetricsForPolicial(policialId) {
  const [legacy, pi] = await Promise.all([
    permutasService.findMatchesForPolicial(policialId),
    computeMatchesForPolicial(policialId),
  ]);

  const metricas_unificadas = mergeUnifiedMetrics(legacy, pi);
  const cacheHitPi = !!pi.cache?.hit;

  return {
    metricas_unificadas,
    metricas_legado: legacy.metricas || buildLegacyMotorMetrics(legacy),
    metricas_inteligente:
      pi.metricas || buildPiMotorMetrics(pi, { cache: pi.cache || {} }),
    cache_hit: {
      legado: false,
      inteligente: cacheHitPi,
    },
    computed_at: metricas_unificadas.meta.computed_at,
    dashboard: {
      interessados: countInteressadosUnified(legacy, pi),
      matches_compativeis: countCompativelDashboardUnified(legacy, pi),
    },
  };
}

module.exports = {
  getUnifiedMetricsForPolicial,
};
