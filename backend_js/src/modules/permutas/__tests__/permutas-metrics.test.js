const {
  countInteressadosUnified,
  buildLegacyMotorMetrics,
  mergeUnifiedMetrics,
  buildPiMotorMetrics,
} = require('../permutas-metrics');

function match(id) {
  return { id, nome: `P${id}`, forca_sigla: 'PM' };
}

describe('permutas-metrics — regressão dashboard 3 vs Permutas 14', () => {
  test('legado isolado reporta 3 interessados', () => {
    const legacy = {
      diretas: [],
      proximas: [],
      interessados: [match(1), match(2), match(3)],
      triangulares: [],
      triangulares_proximas: [],
    };
    const metricas = buildLegacyMotorMetrics(legacy);
    expect(metricas.interested_candidates).toBe(3);
    expect(countInteressadosUnified(legacy, null)).toBe(3);
  });

  test('unificado legado 3 + PI 11 = 14 interessados (cenário típico)', () => {
    const legacy = {
      diretas: [],
      proximas: [],
      interessados: [match(1), match(2), match(3)],
      triangulares: [],
      triangulares_proximas: [],
    };
    const pi = {
      diretas: [],
      proximas: [],
      interessados: Array.from({ length: 11 }, (_, i) => match(100 + i)),
      triangulares: [],
      ciclos_n: [],
      cache: { hit: true },
    };

    expect(countInteressadosUnified(legacy, pi)).toBe(14);

    const unified = mergeUnifiedMetrics(legacy, pi);
    expect(unified.interested_candidates).toBe(14);
    expect(unified.meta.algorithm_version).toBe('unificado_v1');
  });

  test('deduplica interessado legado quando ID já aparece na PI', () => {
    const legacy = {
      interessados: [match(5), match(6)],
      diretas: [],
      proximas: [],
      triangulares: [],
      triangulares_proximas: [],
    };
    const pi = {
      interessados: [match(10)],
      diretas: [match(5)],
      proximas: [],
      triangulares: [],
      ciclos_n: [],
    };

    expect(countInteressadosUnified(legacy, pi)).toBe(2);
  });

  test('buildPiMotorMetrics expõe buckets quando bucket_meta presente', () => {
    const pi = {
      diretas: [{ id: 1 }],
      proximas: [],
      interessados: [],
      triangulares: [],
      ciclos_n: [],
      bucket_meta: {
        diretas: { returned_count: 1, available_count: 150, truncated: true },
        interessados: { returned_count: 0, available_count: 0, truncated: false },
      },
    };
    const metricas = buildPiMotorMetrics(pi, { cache: { hit: false } });
    expect(metricas.meta.truncated).toBe(true);
    expect(metricas.meta.available_count).toBe(150);
    expect(metricas.meta.buckets.diretas.available_count).toBe(150);
  });
});
