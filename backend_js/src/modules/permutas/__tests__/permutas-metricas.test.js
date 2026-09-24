jest.mock('../permutas.service', () => ({
  findMatchesForPolicial: jest.fn(),
}));

jest.mock('../../permutas-inteligentes/permutas-inteligentes.service', () => ({
  computeMatchesForPolicial: jest.fn(),
}));

const permutasService = require('../permutas.service');
const { computeMatchesForPolicial } = require('../../permutas-inteligentes/permutas-inteligentes.service');
const { getUnifiedMetricsForPolicial } = require('../permutas-metricas.service');
const { sliceRankedBucket } = require('../../permutas-inteligentes/permutas-inteligentes.graph');

describe('permutas-metricas.service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('GET /metricas agrega legado + PI com metricas_unificadas', async () => {
    permutasService.findMatchesForPolicial.mockResolvedValue({
      interessados: [{ id: 1 }, { id: 2 }, { id: 3 }],
      diretas: [],
      proximas: [],
      triangulares: [],
      triangulares_proximas: [],
      metricas: {
        interested_candidates: 3,
        meta: { cache_hit: false, algorithm_version: 'legado_v1' },
      },
    });

    computeMatchesForPolicial.mockResolvedValue({
      interessados: Array.from({ length: 11 }, (_, i) => ({ id: 100 + i })),
      diretas: [],
      proximas: [],
      triangulares: [],
      ciclos_n: [],
      cache: { hit: true, computed_at: new Date('2026-03-24T12:00:00.000Z') },
      metricas: {
        interested_candidates: 11,
        meta: { cache_hit: true, algorithm_version: 'inteligente_v1' },
      },
    });

    const data = await getUnifiedMetricsForPolicial(42);

    expect(data.metricas_unificadas.interested_candidates).toBe(14);
    expect(data.metricas_unificadas.meta.algorithm_version).toBe('unificado_v1');
    expect(data.dashboard.interessados).toBe(14);
    expect(data.cache_hit.legado).toBe(false);
    expect(data.cache_hit.inteligente).toBe(true);
    expect(permutasService.findMatchesForPolicial).toHaveBeenCalledWith(42);
    expect(computeMatchesForPolicial).toHaveBeenCalledWith(42);
  });
});

describe('sliceRankedBucket — truncamento PI', () => {
  test('preenche available_count antes do slice e truncated quando corta', () => {
    const items = Array.from({ length: 5 }, (_, i) => ({ id: i, score: i }));
    const result = sliceRankedBucket(items, 3);

    expect(result.items).toHaveLength(3);
    expect(result.available_count).toBe(5);
    expect(result.returned_count).toBe(3);
    expect(result.truncated).toBe(true);
  });

  test('truncated false quando abaixo do limite', () => {
    const result = sliceRankedBucket([{ id: 1, score: 1 }], 10);
    expect(result.truncated).toBe(false);
    expect(result.available_count).toBe(1);
  });
});
