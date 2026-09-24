// Métricas canônicas — alinhadas a docs/metricas-canonicas.md e PermutasUnificadasUtils (Flutter)

const {
  MAX_CYCLES,
  MAX_DIRECTAS,
  MAX_INTERESSADOS,
} = require('../permutas-inteligentes/permutas-inteligentes.graph');

function piPolicialIds(piResult) {
  const ids = new Set();
  if (!piResult) return ids;
  for (const m of piResult.diretas || []) ids.add(m.id);
  for (const m of piResult.proximas || []) ids.add(m.id);
  for (const m of piResult.interessados || []) ids.add(m.id);
  for (const t of piResult.triangulares || []) {
    if (t.policialB?.id) ids.add(t.policialB.id);
    if (t.policialC?.id) ids.add(t.policialC.id);
  }
  for (const c of piResult.ciclos_n || []) {
    for (const p of c.participantes || []) {
      if (p.id > 0) ids.add(p.id);
    }
  }
  return ids;
}

function filterOriginalMatches(matches, piIds) {
  return (matches || []).filter((m) => !piIds.has(m.id));
}

function triangularKey(t) {
  return `${t.policialB.id}_${t.policialC.id}`;
}

function piTriangularesExatas(piResult) {
  if (!piResult) return [];
  return (piResult.triangulares || []).filter((t) => !t.por_aproximacao);
}

function filterDuplicateTriangulares(classic, piTriangulares) {
  const keys = new Set(piTriangulares.map(triangularKey));
  return classic.filter((t) => !keys.has(triangularKey(t)));
}

function uniqueIdsFromMatches(lists) {
  const ids = new Set();
  for (const list of lists) {
    for (const m of list || []) {
      if (m?.id != null) ids.add(m.id);
    }
  }
  return ids;
}

function returnedCountLegacy(result) {
  const tri = result.triangulares || [];
  const triProx = result.triangulares_proximas || [];
  return (
    (result.diretas?.length || 0) +
    (result.proximas?.length || 0) +
    (result.interessados?.length || 0) +
    tri.length +
    triProx.length
  );
}

function returnedCountPi(result) {
  return (
    (result.diretas?.length || 0) +
    (result.proximas?.length || 0) +
    (result.interessados?.length || 0) +
    (result.triangulares?.length || 0) +
    (result.ciclos_n?.length || 0)
  );
}

function proximityCountLegacy(result) {
  const triProx = (result.triangulares_proximas || []).length;
  return (result.proximas?.length || 0) + triProx;
}

function proximityCountPi(result) {
  const approxTri = (result.triangulares || []).filter((t) => t.por_aproximacao).length;
  return (result.proximas?.length || 0) + approxTri;
}

function buildMeta({
  algorithm_version,
  cache_hit = false,
  computed_at = null,
  truncated = false,
  returned_count = 0,
  available_count = null,
  buckets = null,
}) {
  const meta = {
    computed_at: computed_at ? new Date(computed_at).toISOString() : null,
    cache_hit: !!cache_hit,
    algorithm_version,
    truncated: !!truncated,
    returned_count,
    available_count,
  };
  if (buckets && Object.keys(buckets).length > 0) {
    meta.buckets = buckets;
  }
  return meta;
}

function aggregateBucketMeta(bucketMeta) {
  if (!bucketMeta || typeof bucketMeta !== 'object') {
    return { truncated: false, available_count: null, buckets: null };
  }
  const buckets = {};
  let truncated = false;
  let availableSum = 0;
  for (const [key, value] of Object.entries(bucketMeta)) {
    if (!value) continue;
    buckets[key] = {
      returned_count: value.returned_count ?? 0,
      available_count: value.available_count ?? 0,
      truncated: !!value.truncated,
    };
    if (value.truncated) truncated = true;
    availableSum += value.available_count ?? 0;
  }
  return {
    truncated,
    available_count: truncated ? availableSum : null,
    buckets: Object.keys(buckets).length ? buckets : null,
  };
}

function buildLegacyMotorMetrics(result, { computed_at = null } = {}) {
  const direct = result.diretas?.length || 0;
  const proximity = proximityCountLegacy(result);
  const interested = result.interessados?.length || 0;
  const cycles = 0;
  const ids = uniqueIdsFromMatches([
    result.diretas,
    result.proximas,
    result.interessados,
  ]);
  for (const t of [...(result.triangulares || []), ...(result.triangulares_proximas || [])]) {
    if (t.policialB?.id) ids.add(t.policialB.id);
    if (t.policialC?.id) ids.add(t.policialC.id);
  }

  return {
    direct_matches: direct,
    proximity_matches: proximity,
    interested_candidates: interested,
    cycles,
    total_unique_candidates: ids.size,
    meta: buildMeta({
      algorithm_version: 'legado_v1',
      cache_hit: false,
      computed_at: computed_at || new Date(),
      truncated: false,
      returned_count: returnedCountLegacy(result),
      available_count: null,
    }),
  };
}

function piTruncated(result) {
  if (result.bucket_meta) {
    return aggregateBucketMeta(result.bucket_meta).truncated;
  }
  const d = result.diretas?.length || 0;
  const p = result.proximas?.length || 0;
  const i = result.interessados?.length || 0;
  const t = result.triangulares?.length || 0;
  const c = result.ciclos_n?.length || 0;
  return (
    d >= MAX_DIRECTAS ||
    p >= MAX_DIRECTAS ||
    i >= MAX_INTERESSADOS ||
    t >= MAX_CYCLES ||
    c >= MAX_CYCLES
  );
}

function buildPiMotorMetrics(result, { cache = {} } = {}) {
  const direct = result.diretas?.length || 0;
  const proximity = proximityCountPi(result);
  const interested = result.interessados?.length || 0;
  const cycles = result.ciclos_n?.length || 0;
  const ids = uniqueIdsFromMatches([
    result.diretas,
    result.proximas,
    result.interessados,
  ]);
  for (const t of result.triangulares || []) {
    if (t.policialB?.id) ids.add(t.policialB.id);
    if (t.policialC?.id) ids.add(t.policialC.id);
  }
  for (const c of result.ciclos_n || []) {
    for (const p of c.participantes || []) {
      if (p.id > 0) ids.add(p.id);
    }
  }

  const computedAt =
    cache.computed_at || cache.graph_computed_at || new Date();

  const bucketAgg = aggregateBucketMeta(result.bucket_meta);

  return {
    direct_matches: direct,
    proximity_matches: proximity,
    interested_candidates: interested,
    cycles,
    total_unique_candidates: ids.size,
    meta: buildMeta({
      algorithm_version: 'inteligente_v1',
      cache_hit: !!cache.hit,
      computed_at: computedAt,
      truncated: bucketAgg.truncated || piTruncated(result),
      returned_count: returnedCountPi(result),
      available_count: bucketAgg.available_count,
      buckets: bucketAgg.buckets,
    }),
  };
}

function countInteressadosUnified(legacyResult, piResult) {
  const piIds = piPolicialIds(piResult);
  let count = 0;
  if (legacyResult) {
    count += filterOriginalMatches(legacyResult.interessados, piIds).length;
  }
  if (piResult) {
    count += (piResult.interessados || []).length;
  }
  return count;
}

function countCompativelDashboardUnified(legacyResult, piResult) {
  const piIds = piPolicialIds(piResult);
  let count = piResult?.diretas?.length || 0;
  count += piTriangularesExatas(piResult).length;
  count += piResult?.ciclos_n?.length || 0;
  if (legacyResult) {
    count += filterOriginalMatches(legacyResult.diretas, piIds).length;
    const piExactTri = piTriangularesExatas(piResult);
    count += filterDuplicateTriangulares(
      legacyResult.triangulares || [],
      piExactTri
    ).length;
  }
  return count;
}

function collectUnifiedPersonIds(legacyResult, piResult) {
  const piIds = piPolicialIds(piResult);
  const ids = new Set();
  const addMatch = (m) => {
    if (m?.id != null) ids.add(m.id);
  };
  const addTri = (t) => {
    if (t?.policialB?.id) ids.add(t.policialB.id);
    if (t?.policialC?.id) ids.add(t.policialC.id);
  };

  for (const m of piResult?.interessados || []) addMatch(m);
  for (const m of filterOriginalMatches(legacyResult?.interessados, piIds)) addMatch(m);

  for (const m of piResult?.diretas || []) addMatch(m);
  for (const m of filterOriginalMatches(legacyResult?.diretas, piIds)) addMatch(m);

  for (const m of piResult?.proximas || []) addMatch(m);
  for (const m of filterOriginalMatches(legacyResult?.proximas, piIds)) addMatch(m);

  const piExactTri = piTriangularesExatas(piResult || {});
  for (const t of piExactTri) addTri(t);
  for (const t of filterDuplicateTriangulares(
    legacyResult?.triangulares || [],
    piExactTri
  )) {
    addTri(t);
  }

  for (const t of (piResult?.triangulares || []).filter((x) => x.por_aproximacao)) addTri(t);
  for (const t of legacyResult?.triangulares_proximas || []) addTri(t);

  for (const c of piResult?.ciclos_n || []) {
    for (const p of c.participantes || []) addMatch(p);
  }

  return ids;
}

function mergeUnifiedMetrics(legacyResult, piResult) {
  const direct =
    (piResult?.diretas?.length || 0) +
    filterOriginalMatches(legacyResult?.diretas, piPolicialIds(piResult)).length;

  const piIds = piPolicialIds(piResult);
  let proximity = proximityCountPi(piResult || {});
  if (legacyResult) {
    proximity += filterOriginalMatches(legacyResult.proximas, piIds).length;
    proximity += (legacyResult.triangulares_proximas || []).length;
  }

  const interested = countInteressadosUnified(legacyResult, piResult);
  const cycles = piResult?.ciclos_n?.length || 0;

  const piBucketAgg = aggregateBucketMeta(piResult?.bucket_meta);

  return {
    direct_matches: direct,
    proximity_matches: proximity,
    interested_candidates: interested,
    cycles,
    total_unique_candidates: collectUnifiedPersonIds(legacyResult, piResult).size,
    meta: buildMeta({
      algorithm_version: 'unificado_v1',
      cache_hit: !!piResult?.cache?.hit,
      computed_at: piResult?.cache?.computed_at || new Date(),
      truncated: piResult ? piTruncated(piResult) : false,
      returned_count:
        (legacyResult ? returnedCountLegacy(legacyResult) : 0) +
        (piResult ? returnedCountPi(piResult) : 0),
      available_count: piBucketAgg.available_count,
      buckets: piBucketAgg.buckets,
    }),
  };
}

function attachLegacyMetrics(result) {
  return {
    ...result,
    metricas: buildLegacyMotorMetrics(result),
  };
}

function attachPiMetrics(result) {
  const { cache, bucket_meta, ...rest } = result;
  return {
    ...rest,
    bucket_meta: bucket_meta || null,
    cache,
    metricas: buildPiMotorMetrics(result, { cache: cache || {} }),
  };
}

module.exports = {
  piPolicialIds,
  filterOriginalMatches,
  countInteressadosUnified,
  countCompativelDashboardUnified,
  mergeUnifiedMetrics,
  buildLegacyMotorMetrics,
  buildPiMotorMetrics,
  attachLegacyMetrics,
  attachPiMetrics,
  aggregateBucketMeta,
  returnedCountPi,
};
