// Invalidação coordenada PI (grafo + caches de usuários vizinhos no snapshot)

const cacheRepository = require('../permutas-inteligentes/permutas-inteligentes.cache.repository');

function collectNeighborPolicialIds(policialId, adjacency) {
  const affected = new Set();
  if (!adjacency || typeof adjacency.entries !== 'function') {
    return affected;
  }

  for (const [fromId, edges] of adjacency.entries()) {
    if (fromId === policialId) {
      for (const edge of edges || []) {
        if (edge.toId != null) affected.add(edge.toId);
      }
    }
    for (const edge of edges || []) {
      if (edge.toId === policialId && edge.fromId != null) {
        affected.add(edge.fromId);
      }
    }
  }

  affected.delete(policialId);
  return affected;
}

/**
 * Após alteração de intenção/lotação/perfil que afeta o grafo PI.
 * @param {number} policialId
 * @param {{ invalidateGraph?: boolean }} options
 */
async function invalidatePermutasCachesForPolicial(
  policialId,
  { invalidateGraph = true } = {}
) {
  await cacheRepository.invalidateUserCache(policialId);

  const snapshot = await cacheRepository.getGraphSnapshot();
  if (snapshot?.adjacency) {
    const neighbors = collectNeighborPolicialIds(policialId, snapshot.adjacency);
    await Promise.all(
      [...neighbors].map((id) => cacheRepository.invalidateUserCache(id).catch(() => {}))
    );
  }

  if (invalidateGraph) {
    await cacheRepository.invalidateGraphSnapshot();
  }
}

function schedulePermutasCacheInvalidation(policialId, options = {}) {
  setImmediate(() => {
    invalidatePermutasCachesForPolicial(policialId, options).catch(() => {});
  });
}

module.exports = {
  collectNeighborPolicialIds,
  invalidatePermutasCachesForPolicial,
  schedulePermutasCacheInvalidation,
};
