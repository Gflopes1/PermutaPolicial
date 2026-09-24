// Motor experimental isolado — não usa permutas.service legado

const pLimit = require('p-limit');
const dataRepository = require('./permutas-inteligentes.data.repository');
const cacheRepository = require('./permutas-inteligentes.cache.repository');
const notificacoesRepository = require('../notificacoes/notificacoes.repository');
const {
  MAX_CYCLE_SIZE,
  MAX_CYCLES,
  MAX_DIRECTAS,
  MAX_INTERESSADOS,
  buildEdges,
  findMatchesForUser,
  filterNodesForUser,
  countAdjacencyEdges,
  findCyclesForUser,
} = require('./permutas-inteligentes.graph');
const perfLogger = require('../../core/utils/performance-logger');
const {
  attachPiMetrics,
  buildPiMotorMetrics,
  returnedCountPi,
} = require('../permutas/permutas-metrics');

const JOB_CONCURRENCY = Number(process.env.PI_JOB_CONCURRENCY || 5);

let cacheRefreshJobRunning = false;

console.log('[permutas-inteligentes] Limites ativos:', {
  MAX_CYCLE_SIZE,
  MAX_CYCLES,
  MAX_DIRECTAS,
  MAX_INTERESSADOS,
  PI_JOB_CONCURRENCY: JOB_CONCURRENCY,
});

function buildContactStatusMaps(notificacoes) {
  const solicitacoesPendentes = new Map();
  const aceitacoes = new Map();

  notificacoes.forEach((notif) => {
    if (
      notif.tipo === 'SOLICITACAO_CONTATO' &&
      notif.referencia_id &&
      notif.lida === 0
    ) {
      solicitacoesPendentes.set(notif.referencia_id, true);
    } else if (notif.tipo === 'SOLICITACAO_CONTATO_ACEITA' && notif.referencia_id) {
      aceitacoes.set(notif.referencia_id, {
        aceitador_nome: notif.aceitador_nome,
        aceitador_contato: notif.aceitador_contato,
        aceitador_forca_nome: notif.aceitador_forca_nome,
        aceitador_forca_sigla: notif.aceitador_forca_sigla,
        aceitador_estado_sigla: notif.aceitador_estado_sigla,
        aceitador_cidade_nome: notif.aceitador_cidade_nome,
        aceitador_unidade_nome: notif.aceitador_unidade_nome,
        aceitador_posto_nome: notif.aceitador_posto_nome,
      });
    }
  });

  return { solicitacoesPendentes, aceitacoes };
}

function createEnriquecerMatch(solicitacoesPendentes, aceitacoes) {
  return (match) => {
    const matchId = match.id;
    return {
      ...match,
      ja_solicitado: solicitacoesPendentes.has(matchId),
      aceitou_compartilhar: aceitacoes.has(matchId),
      dados_aceitacao: aceitacoes.get(matchId) || null,
    };
  };
}

function applyEnrichmentToResult(result, enriquecerMatch) {
  return {
    ...result,
    diretas: (result.diretas || []).map(enriquecerMatch),
    proximas: (result.proximas || []).map(enriquecerMatch),
    interessados: (result.interessados || []).map(enriquecerMatch),
    triangulares: (result.triangulares || []).map((t) => ({
      ...t,
      policialB: enriquecerMatch(t.policialB),
      policialC: enriquecerMatch(t.policialC),
    })),
    ciclos_n: (result.ciclos_n || []).map((c) => ({
      ...c,
      participantes: (c.participantes || []).map(enriquecerMatch),
    })),
  };
}

async function enrichResultWithContactStatus(policialId, result) {
  const notificacoes = await notificacoesRepository.findContactStatusByUsuario(policialId);
  const { solicitacoesPendentes, aceitacoes } = buildContactStatusMaps(notificacoes);
  const enriquecerMatch = createEnriquecerMatch(solicitacoesPendentes, aceitacoes);
  return applyEnrichmentToResult(result, enriquecerMatch);
}

async function getOrBuildGraphSnapshot(forceRebuild = false) {
  try {
    if (!forceRebuild) {
      const cached = await cacheRepository.getGraphSnapshot();
      if (cached) {
        console.log(
          `[permutas-inteligentes] Snapshot em cache: ${cached.node_count} nós, ${cached.edge_count} arestas`
        );
        return { ...cached, graph_cache_hit: true };
      }
    }

    console.log('[permutas-inteligentes] Construindo grafo...');
    const nodes = await dataRepository.loadGraphNodes();
    console.log(`[permutas-inteligentes] ${nodes.length} nós carregados`);

    const buildStart = Date.now();
    const { adjacency } = buildEdges(nodes);
    const build_ms = Date.now() - buildStart;
    const edgeCount = countAdjacencyEdges(adjacency);

    perfLogger.record('PI', 'graph_build', {
      build_ms,
      nodes: nodes.length,
      edges: edgeCount,
    });

    const meta = await cacheRepository.saveGraphSnapshot(nodes, edgeCount, adjacency);

    console.log(
      `[permutas-inteligentes] Grafo construído em ${build_ms}ms — ${nodes.length} nós, ${edgeCount} arestas`
    );

    return {
      nodes,
      adjacency,
      node_count: nodes.length,
      edge_count: edgeCount,
      computed_at: new Date(),
      expires_at: meta.expires_at,
      build_ms,
      graph_cache_hit: false,
    };
  } catch (error) {
    console.error('[permutas-inteligentes] ERRO ao construir grafo:', error);
    throw error;
  }
}

function buildConfiguracao(profile, intencoesCount) {
  const aceitaInterestadual = profile.lotacao_interestadual === true;
  let regra =
    intencoesCount === 0
      ? 'Adicione suas intenções de destino para usar o motor inteligente.'
      : aceitaInterestadual
        ? `Motor experimental: permuta interestadual com qualquer ${profile.tipo_permuta}.`
        : `Motor experimental: apenas ${profile.forca_sigla} (mesma corporação).`;

  regra += ' Intenção ESTADO só na permuta interestadual; intraestadual usa unidade e município.';

  return {
    aceita_permuta_interestadual: aceitaInterestadual,
    tipo_permuta: profile.tipo_permuta,
    forca_sigla: profile.forca_sigla,
    regra_permuta: regra,
    tem_raio_configurado: true,
    motor: 'inteligente_v1',
    experimental: true,
  };
}

function buildSummaryPayload(result, cacheInfo = {}) {
  const metricas =
    result.metricas ||
    buildPiMotorMetrics(result, { cache: cacheInfo.cache || result.cache || {} });
  const breakdown = {
    direct_matches: metricas.direct_matches,
    proximity_matches: metricas.proximity_matches,
    interested_candidates: metricas.interested_candidates,
    cycles: metricas.cycles,
    triangulares: result.triangulares?.length || 0,
    total_returned_items: returnedCountPi(result),
  };

  return {
    breakdown,
    metricas,
    total_matches: breakdown.total_returned_items,
    total_matches_deprecated: true,
    total_matches_note:
      'Soma de itens retornados em todas as buckets PI; não equivale a interessados nem a matches compatíveis unificados. Use breakdown ou metricas.',
    cache_hit: !!cacheInfo.cache_hit,
    computed_at: cacheInfo.computed_at ?? result.cache?.computed_at ?? null,
    expires_at: cacheInfo.expires_at ?? result.cache?.expires_at ?? null,
  };
}

async function computeMatchesForPolicial(policialId, { forceRefresh = false } = {}) {
  const profile = await dataRepository.loadPolicialProfile(policialId);

  if (!profile) {
    return emptyResult('Perfil não encontrado.');
  }

  const hasLocation = profile.unidade_atual_id || profile.municipio_atual_id;
  if (!hasLocation) {
    return emptyResult('Defina sua lotação atual para ver combinações inteligentes.');
  }

  if (!forceRefresh) {
    const cached = await cacheRepository.getUserCache(policialId);
    if (cached) {
      const enriched = await enrichResultWithContactStatus(policialId, cached.result);
      return attachPiMetrics({
        ...enriched,
        cache: {
          hit: true,
          computed_at: cached.computed_at,
          expires_at: cached.expires_at,
        },
      });
    }
  }

  const snapshot = await getOrBuildGraphSnapshot(false);
  const userNode = snapshot.nodes.find((n) => n.id === policialId);

  if (!userNode || userNode.intencoes.length === 0) {
    return emptyResult('Adicione intenções de permuta para usar o motor inteligente.');
  }

  const scopedNodes = filterNodesForUser(userNode, snapshot.nodes);
  const matchStart = Date.now();
  const matches = findMatchesForUser(userNode, scopedNodes, snapshot.adjacency);
  const match_ms = Date.now() - matchStart;

  perfLogger.record('PI', 'user_matches', {
    match_ms,
    build_ms: matches.graph_stats?.build_ms ?? null,
    cycles_ms: matches.graph_stats?.cycles_ms ?? null,
    nodes: matches.graph_stats?.nodes ?? scopedNodes.length,
    edges: matches.graph_stats?.edges ?? 0,
    cycles_found: matches.graph_stats?.cycles_found ?? 0,
    policial_id: policialId,
    cache_refresh: forceRefresh,
  });

  const notificacoes = await notificacoesRepository.findContactStatusByUsuario(policialId);
  const { solicitacoesPendentes, aceitacoes } = buildContactStatusMaps(notificacoes);
  const enriquecerMatch = createEnriquecerMatch(solicitacoesPendentes, aceitacoes);

  const resultadoBase = {
    configuracao: buildConfiguracao(profile, userNode.intencoes.length),
    diretas: matches.diretas,
    proximas: matches.proximas,
    interessados: matches.interessados,
    triangulares: matches.triangulares,
    triangulares_proximas: [],
    ciclos_n: matches.ciclos_n,
    bucket_meta: matches.bucket_meta || null,
    graph_stats: matches.graph_stats,
    cache: {
      hit: false,
      graph_cache_hit: !!snapshot.graph_cache_hit,
      graph_computed_at: snapshot.computed_at,
      graph_expires_at: snapshot.expires_at,
    },
  };

  const resultado = applyEnrichmentToResult(resultadoBase, enriquecerMatch);

  const cacheMeta = await cacheRepository.saveUserCache(policialId, resultado);
  resultado.cache.computed_at = new Date();
  resultado.cache.expires_at = cacheMeta.expires_at;
  resultado.cache.match_count = cacheMeta.match_count;

  return attachPiMetrics(resultado);
}

function emptyResult(regra) {
  return {
    configuracao: {
      regra_permuta: regra,
      motor: 'inteligente_v1',
      experimental: true,
      tem_raio_configurado: false,
      aceita_permuta_interestadual: false,
      tipo_permuta: 'N/A',
      forca_sigla: 'N/A',
    },
    diretas: [],
    proximas: [],
    interessados: [],
    triangulares: [],
    triangulares_proximas: [],
    ciclos_n: [],
    graph_stats: { nodes: 0, edges: 0 },
    cache: { hit: false },
  };
}

async function getSummaryForPolicial(policialId) {
  const cached = await cacheRepository.getUserCache(policialId);
  if (cached) {
    const enriched = attachPiMetrics({
      ...cached.result,
      cache: {
        hit: true,
        computed_at: cached.computed_at,
        expires_at: cached.expires_at,
      },
    });
    return buildSummaryPayload(enriched, {
      cache_hit: true,
      computed_at: cached.computed_at,
      expires_at: cached.expires_at,
      cache: { hit: true, computed_at: cached.computed_at },
    });
  }

  const result = await computeMatchesForPolicial(policialId);
  return buildSummaryPayload(result, {
    cache_hit: !!result.cache?.hit,
    computed_at: result.cache?.computed_at || null,
    expires_at: result.cache?.expires_at || null,
  });
}

function resolveUserIdsForCacheRefresh(snapshot, userLimit) {
  const fromGraph = (snapshot?.nodes || []).map((n) => n.id);
  if (fromGraph.length > 0) {
    return userLimit > 0 ? fromGraph.slice(0, userLimit) : fromGraph;
  }
  return null;
}

async function runCacheRefreshJob({ rebuildGraph = true, userLimit = 0 } = {}) {
  if (cacheRefreshJobRunning) {
    console.log('[permutas-inteligentes] Job ignorado — execução anterior ainda em andamento.');
    return { skipped: true, reason: 'job_already_running' };
  }

  cacheRefreshJobRunning = true;
  const limitUsers = userLimit > 0 ? userLimit : Number(process.env.PI_JOB_USER_LIMIT || 0);
  console.log('[permutas-inteligentes] Iniciando job de refresh do cache...');

  try {
  await cacheRepository.purgeExpired();

  let graphStats = null;
  let snapshot = null;

  if (rebuildGraph) {
    await cacheRepository.invalidateAllUserCaches();
    snapshot = await getOrBuildGraphSnapshot(true);
    graphStats = snapshot;
  } else {
    snapshot = await getOrBuildGraphSnapshot(false);
  }

  let userIds = resolveUserIdsForCacheRefresh(snapshot, limitUsers);
  if (!userIds || userIds.length === 0) {
    userIds = await dataRepository.findActivePolicialIds(limitUsers);
  }

  console.log(
    `[permutas-inteligentes] Cacheando matches para ${userIds.length} usuário(s) (concorrência: ${JOB_CONCURRENCY})...`
  );

  let processados = 0;
  let erros = 0;
  const logEvery = Math.max(25, Math.floor(userIds.length / 10)) || 25;

  const limit = pLimit(JOB_CONCURRENCY);
  const tasks = userIds.map((userId) =>
    limit(() =>
      computeMatchesForPolicial(userId, { forceRefresh: true })
        .then(() => {
          processados += 1;
          if (
            processados === 1 ||
            processados % logEvery === 0 ||
            processados === userIds.length
          ) {
            console.log(
              `[permutas-inteligentes] Progresso cache: ${processados}/${userIds.length}`
            );
          }
        })
        .catch((error) => {
          erros += 1;
          console.error(
            `[permutas-inteligentes] Erro ao cachear usuário ${userId}:`,
            error.message
          );
        })
    )
  );

  await Promise.all(tasks);

  console.log(
    `[permutas-inteligentes] Job concluído — ${processados} usuários cacheados, ${erros} erros`
  );

  return {
    graph_rebuilt: rebuildGraph,
    graph_stats: graphStats
      ? {
          nodes: graphStats.node_count,
          edges: graphStats.edge_count,
          build_ms: graphStats.build_ms,
        }
      : null,
    usuarios_total: userIds.length,
    usuarios_processados: processados,
    erros,
  };
  } finally {
    cacheRefreshJobRunning = false;
  }
}

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function buildNodeTooltip(node) {
  const intencoesCount = (node.intencoes || []).length;
  if (node.ocultar_no_mapa) {
    return `<b>Policial oculto</b><br>ID: ${node.id}<br>Intenções: ${intencoesCount}`;
  }
  const local = [node.municipio_atual, node.estado_atual].filter(Boolean).join('-');
  return [
    `<b>${escapeHtml(node.nome)}</b>`,
    `${escapeHtml(node.forca_sigla || 'N/A')}${local ? ` · ${escapeHtml(local)}` : ''}`,
    `Intenções: ${intencoesCount}`,
  ].join('<br>');
}

function collectCycleInfo(adjacency, maxNodesToScan = 500) {
  const cycleEdgeKeys = new Set();
  const nodesInCycles = new Set();
  let scanned = 0;

  for (const userId of adjacency.keys()) {
    if (scanned >= maxNodesToScan) break;
    scanned += 1;
    const cycles = findCyclesForUser(userId, adjacency);
    for (const cycle of cycles) {
      for (const edge of cycle.edges) {
        cycleEdgeKeys.add(`${edge.fromId}-${edge.toId}`);
      }
      cycle.participantIds.slice(0, -1).forEach((id) => nodesInCycles.add(id));
    }
  }

  return {
    cycle_edge_keys: [...cycleEdgeKeys],
    nodes_in_cycles: nodesInCycles.size,
  };
}

async function getAdminGraphData(forceRebuild = false) {
  const snapshot = await getOrBuildGraphSnapshot(forceRebuild);
  const nodes = snapshot.nodes || [];
  const adjacencyMap =
    snapshot.adjacency instanceof Map
      ? snapshot.adjacency
      : new Map(snapshot.adjacency || []);

  const forces = {};
  const estadosSet = new Set();

  const visNodes = nodes.map((node) => {
    if (node.forca_id != null) {
      forces[node.forca_id] = {
        sigla: node.forca_sigla || 'N/A',
        nome: node.forca_nome || node.forca_sigla || 'Corporação',
      };
    }
    if (node.estado_atual) estadosSet.add(node.estado_atual);

    const hidden = !!node.ocultar_no_mapa;
    const firstName = (node.nome || '').trim().split(/\s+/)[0];

    return {
      id: node.id,
      label: hidden ? `ID:${node.id}` : firstName || `ID:${node.id}`,
      title: buildNodeTooltip(node),
      group: String(node.forca_id ?? '0'),
      value: Math.max(1, (node.intencoes || []).length),
      em_destaque: !!node.em_destaque,
      lotacao_interestadual: !!node.lotacao_interestadual,
      municipio_atual: node.municipio_atual,
      estado_atual: node.estado_atual,
      forca_sigla: node.forca_sigla,
      forca_nome: node.forca_nome,
      ocultar_no_mapa: hidden,
      nome: hidden ? null : node.nome,
      intencoes: (node.intencoes || []).map((intencao) => ({
        tipo: intencao.tipo_intencao,
        destino: intencao.destino_label,
        prioridade: intencao.prioridade,
      })),
    };
  });

  const visEdges = [];
  for (const [, edgeList] of adjacencyMap.entries()) {
    for (const edge of edgeList) {
      visEdges.push({
        id: `${edge.fromId}-${edge.toId}-${edge.prioridade}-${edge.tipo_intencao}`,
        from: edge.fromId,
        to: edge.toId,
        value: edge.exato ? 2 : 1,
        dashes: !edge.exato,
        title: `${edge.tipo_intencao} · P${edge.prioridade}${
          edge.distancia_km ? ` · ${edge.distancia_km}km` : ''
        }`,
        color: edge.exato ? '#00E676' : '#FFB74D',
        exato: !!edge.exato,
      });
    }
  }

  const cycleInfo =
    nodes.length <= 2000
      ? collectCycleInfo(adjacencyMap)
      : { cycle_edge_keys: [], nodes_in_cycles: 0 };

  return {
    nodes: visNodes,
    edges: visEdges,
    graph_stats: {
      node_count: snapshot.node_count ?? nodes.length,
      edge_count: snapshot.edge_count ?? visEdges.length,
      computed_at: snapshot.computed_at,
      expires_at: snapshot.expires_at,
      build_ms: snapshot.build_ms ?? null,
      nodes_in_cycles: cycleInfo.nodes_in_cycles,
    },
    cycle_edge_keys: cycleInfo.cycle_edge_keys,
    forces,
    estados: [...estadosSet].sort(),
  };
}

async function rebuildAdminGraphSync() {
  const snapshot = await getOrBuildGraphSnapshot(true);
  return {
    nodes: snapshot.node_count ?? snapshot.nodes.length,
    edges: snapshot.edge_count ?? countAdjacencyEdges(snapshot.adjacency),
    build_ms: snapshot.build_ms,
    computed_at: snapshot.computed_at,
  };
}

function buildCityKey(municipio, estado) {
  const name = (municipio || '').trim();
  if (!name) return null;
  return `${name}|${(estado || '').trim()}`;
}

function parsePosterCityLimit(value) {
  if (value == null || value === '' || value === 'all') return null;
  const parsed = parseInt(value, 10);
  if (Number.isNaN(parsed) || parsed <= 0) return null;
  return parsed;
}

function collectPosterFilterMetadata(nodes) {
  const forces = {};
  const estadosSet = new Set();

  for (const node of nodes) {
    if (node.forca_id != null) {
      forces[node.forca_id] = {
        id: node.forca_id,
        sigla: node.forca_sigla || 'N/A',
        nome: node.forca_nome || node.forca_sigla || 'Corporação',
      };
    }
    if (node.estado_atual) estadosSet.add(node.estado_atual);
  }

  return {
    forces: Object.values(forces).sort((a, b) =>
      String(a.sigla).localeCompare(String(b.sigla), 'pt-BR')
    ),
    estados: [...estadosSet].sort(),
  };
}

function filterNodesForPoster(nodes, { estado, forcaId } = {}) {
  let filtered = nodes;
  if (forcaId != null && forcaId !== '') {
    filtered = filtered.filter((node) => String(node.forca_id) === String(forcaId));
  }
  if (estado) {
    filtered = filtered.filter((node) => node.estado_atual === estado);
  }
  return filtered;
}

function buildFilteredAdjacency(adjacencyMap, allowedNodeIds) {
  const filtered = new Map();
  for (const [fromId, edgeList] of adjacencyMap.entries()) {
    if (!allowedNodeIds.has(fromId)) continue;
    const edges = edgeList.filter((edge) => allowedNodeIds.has(edge.toId));
    if (edges.length) filtered.set(fromId, edges);
  }
  return filtered;
}

function buildPosterCityIndex(nodes) {
  const cities = new Map();
  const nodeCityKey = new Map();

  for (const node of nodes) {
    const key = buildCityKey(node.municipio_atual, node.estado_atual);
    if (!key) continue;

    nodeCityKey.set(node.id, key);
    if (!cities.has(key)) {
      cities.set(key, {
        key,
        name: node.municipio_atual,
        estado: node.estado_atual,
        lat: node.lat,
        lng: node.lng,
        volume: 0,
      });
    }

    const city = cities.get(key);
    city.volume += 1;
    if (node.lat != null && node.lng != null) {
      city.lat = node.lat;
      city.lng = node.lng;
    }
  }

  return { cities, nodeCityKey };
}

async function getAdminGraphPosterData(forceRebuild = false, filters = {}) {
  const snapshot = await getOrBuildGraphSnapshot(forceRebuild);
  const allNodes = snapshot.nodes || [];
  const adjacencyMap =
    snapshot.adjacency instanceof Map
      ? snapshot.adjacency
      : new Map(snapshot.adjacency || []);

  const { estado = null, forcaId = null, cityLimit = null } = filters;
  const filterMeta = collectPosterFilterMetadata(allNodes);
  const filteredNodes = filterNodesForPoster(allNodes, { estado, forcaId });
  const allowedNodeIds = new Set(filteredNodes.map((node) => node.id));
  const filteredAdjacency = buildFilteredAdjacency(adjacencyMap, allowedNodeIds);

  const { cities, nodeCityKey } = buildPosterCityIndex(filteredNodes);
  const citiesWithCoords = [...cities.values()]
    .filter((city) => city.lat != null && city.lng != null)
    .sort((a, b) => b.volume - a.volume);

  const totalCityCount = citiesWithCoords.length;
  const effectiveCityLimit =
    cityLimit == null
      ? totalCityCount
      : Math.min(Math.max(cityLimit, 1), totalCityCount);

  const visibleCities =
    cityLimit == null
      ? citiesWithCoords
      : citiesWithCoords.slice(0, effectiveCityLimit);
  const visibleKeys = new Set(visibleCities.map((city) => city.key));

  const routeCounts = new Map();
  for (const [, edgeList] of filteredAdjacency.entries()) {
    for (const edge of edgeList) {
      const fromKey = nodeCityKey.get(edge.fromId);
      const toKey = nodeCityKey.get(edge.toId);
      if (!fromKey || !toKey || fromKey === toKey) continue;
      if (!visibleKeys.has(fromKey) || !visibleKeys.has(toKey)) continue;
      const routeKey = `${fromKey}=>${toKey}`;
      routeCounts.set(routeKey, (routeCounts.get(routeKey) || 0) + 1);
    }
  }

  const routes = [...routeCounts.entries()]
    .map(([routeKey, count]) => {
      const [fromKey, toKey] = routeKey.split('=>');
      const from = cities.get(fromKey);
      const to = cities.get(toKey);
      if (!from || !to) return null;
      return {
        from_key: fromKey,
        to_key: toKey,
        from_name: from.name,
        to_name: to.name,
        count,
      };
    })
    .filter(Boolean)
    .sort((a, b) => b.count - a.count);

  const maxVolume = visibleCities.reduce(
    (max, city) => Math.max(max, city.volume || 0),
    0
  );
  const hubThreshold = Math.max(3, Math.ceil(maxVolume * 0.65));

  const posterCities = visibleCities.map((city) => ({
    key: city.key,
    name: city.name,
    estado: city.estado,
    lat: city.lat,
    lng: city.lng,
    volume: city.volume,
    is_hub: city.volume >= hubThreshold,
  }));

  const cycleInfo =
    filteredNodes.length <= 2000
      ? collectCycleInfo(filteredAdjacency)
      : { cycle_edge_keys: [], nodes_in_cycles: 0 };

  return {
    graph_stats: {
      node_count: filteredNodes.length,
      edge_count: countAdjacencyEdges(filteredAdjacency),
      computed_at: snapshot.computed_at,
      expires_at: snapshot.expires_at,
      build_ms: snapshot.build_ms ?? null,
      nodes_in_cycles: cycleInfo.nodes_in_cycles,
    },
    cities: posterCities,
    routes,
    filters: {
      ...filterMeta,
      applied: {
        estado: estado || null,
        forca_id: forcaId != null && forcaId !== '' ? Number(forcaId) : null,
        city_limit: cityLimit,
      },
      city_count_total: totalCityCount,
      city_count_shown: posterCities.length,
      city_count_without_coords: [...cities.values()].filter(
        (city) => city.lat == null || city.lng == null
      ).length,
      snapshot_node_count: allNodes.length,
      city_limit_min: Math.min(10, totalCityCount || 10),
      city_limit_max: totalCityCount,
    },
  };
}

module.exports = {
  computeMatchesForPolicial,
  getSummaryForPolicial,
  runCacheRefreshJob,
  getOrBuildGraphSnapshot,
  getAdminGraphData,
  getAdminGraphPosterData,
  parsePosterCityLimit,
  rebuildAdminGraphSync,
};
