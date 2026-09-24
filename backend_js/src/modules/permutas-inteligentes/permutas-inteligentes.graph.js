// Grafo direcionado e detecção de ciclos N-way
// Funções puras (sem I/O) — preparado para futura migração a Worker Threads.

const { haversineKm } = require('../../core/utils/geo.utils');
const {
  scoreDirectMatch,
  scoreInteressado,
  scoreCycle,
  sortByScoreDesc,
} = require('./permutas-inteligentes.scoring');

const MAX_CYCLE_SIZE = Number(process.env.PI_MAX_CYCLE_SIZE || 6);
const MAX_CYCLES = Number(process.env.PI_MAX_CYCLES || 40);
const MAX_DIRECTAS = Number(process.env.PI_MAX_DIRECTAS || 100);
const MAX_INTERESSADOS = Number(process.env.PI_MAX_INTERESSADOS || 100);

function locationKey(node) {
  return `${node.unidade_atual_id || 0}:${node.municipio_atual_id || 0}:${node.estado_atual_id || 0}`;
}

function intentionTargetsLocation(intencao, targetNode) {
  if (intencao.tipo_intencao === 'UNIDADE') {
    return intencao.unidade_id && intencao.unidade_id === targetNode.unidade_atual_id;
  }
  if (intencao.tipo_intencao === 'MUNICIPIO') {
    return (
      intencao.municipio_id &&
      intencao.municipio_id === targetNode.municipio_atual_id
    );
  }
  if (intencao.tipo_intencao === 'ESTADO') {
    return intencao.estado_id && intencao.estado_id === targetNode.estado_atual_id;
  }
  return false;
}

function eligibleIntentions(intencoes) {
  return intencoes.filter(
    (i) =>
      i.tipo_intencao === 'UNIDADE' ||
      i.tipo_intencao === 'MUNICIPIO' ||
      i.tipo_intencao === 'ESTADO'
  );
}

function isSameStateLotacao(a, b) {
  return (
    a.estado_atual_id != null &&
    b.estado_atual_id != null &&
    a.estado_atual_id === b.estado_atual_id
  );
}

/** ESTADO só vale na permuta interestadual (lotados em estados diferentes). */
function isEstadoIntentionAllowed(from, to, intencao) {
  if (intencao.tipo_intencao !== 'ESTADO') return true;
  // Intenção ESTADO só vale para quem aceita permuta interestadual
  if (!from.lotacao_interestadual) return false;
  return !isSameStateLotacao(from, to);
}

function intentionProximityToLocation(intencao, targetNode) {
  if (!intencao.raio_km || intencao.raio_km <= 0) return null;
  if (!intencao.destino_lat || !intencao.destino_lng) return null;
  if (!targetNode.lat || !targetNode.lng) return null;

  const dist = haversineKm(
    intencao.destino_lat,
    intencao.destino_lng,
    targetNode.lat,
    targetNode.lng
  );
  if (dist == null || dist > intencao.raio_km) return null;
  return Math.round(dist * 10) / 10;
}

/**
 * Índices invertidos por lotação atual — evita varredura O(N²) em matches exatos.
 * Proximidade (raio_km) ainda avalia nós com coordenadas via haversine.
 */
function buildLocationIndices(nodes) {
  const byMunicipioId = new Map();
  const byUnidadeId = new Map();
  const byEstadoId = new Map();
  const nodesWithCoords = [];

  for (const node of nodes) {
    if (node.municipio_atual_id) {
      const mid = node.municipio_atual_id;
      if (!byMunicipioId.has(mid)) byMunicipioId.set(mid, []);
      byMunicipioId.get(mid).push(node);
    }
    if (node.unidade_atual_id) {
      const uid = node.unidade_atual_id;
      if (!byUnidadeId.has(uid)) byUnidadeId.set(uid, []);
      byUnidadeId.get(uid).push(node);
    }
    if (node.estado_atual_id) {
      const eid = node.estado_atual_id;
      if (!byEstadoId.has(eid)) byEstadoId.set(eid, []);
      byEstadoId.get(eid).push(node);
    }
    if (node.lat && node.lng) {
      nodesWithCoords.push(node);
    }
  }

  return { byMunicipioId, byUnidadeId, byEstadoId, nodesWithCoords };
}

/**
 * Candidatos potenciais para uma intenção (exatos via índice + coords para raio_km).
 * Preserva mesmas regras: UNIDADE, MUNICIPIO, proximidade haversine.
 */
function collectCandidatesForIntention(intencao, indices) {
  const seen = new Set();
  const list = [];

  const add = (node) => {
    if (!seen.has(node.id)) {
      seen.add(node.id);
      list.push(node);
    }
  };

  if (intencao.tipo_intencao === 'UNIDADE' && intencao.unidade_id) {
    for (const n of indices.byUnidadeId.get(intencao.unidade_id) || []) {
      add(n);
    }
  }
  if (intencao.tipo_intencao === 'MUNICIPIO' && intencao.municipio_id) {
    for (const n of indices.byMunicipioId.get(intencao.municipio_id) || []) {
      add(n);
    }
  }
  if (intencao.tipo_intencao === 'ESTADO' && intencao.estado_id) {
    for (const n of indices.byEstadoId.get(intencao.estado_id) || []) {
      add(n);
    }
  }

  if (intencao.raio_km > 0 && intencao.destino_lat && intencao.destino_lng) {
    for (const n of indices.nodesWithCoords) {
      add(n);
    }
  }

  return list;
}

function countAdjacencyEdges(adjacency) {
  return [...adjacency.values()].reduce((acc, list) => acc + list.length, 0);
}

/**
 * Constrói arestas usando índices invertidos — O(N × intenções × candidatos)
 * em vez de O(N²). Mesma semântica: primeira intenção elegível que conecta
 * ao destino define a aresta; ordenação final idêntica.
 */
function buildEdges(nodes) {
  const nodeById = new Map(nodes.map((n) => [n.id, n]));
  const indices = buildLocationIndices(nodes);
  const adjacency = new Map();

  for (const from of nodes) {
    const edgeByToId = new Map();

    for (const intencao of eligibleIntentions(from.intencoes)) {
      const candidates = collectCandidatesForIntention(intencao, indices);

      for (const to of candidates) {
        if (to.id === from.id) continue;
        if (edgeByToId.has(to.id)) continue;
        if (!isEstadoIntentionAllowed(from, to, intencao)) continue;

        const exact = intentionTargetsLocation(intencao, to);
        const proxDist = exact ? null : intentionProximityToLocation(intencao, to);

        if (!exact && proxDist == null) continue;

        edgeByToId.set(to.id, {
          fromId: from.id,
          toId: to.id,
          prioridade: intencao.prioridade,
          tipo_intencao: intencao.tipo_intencao,
          exato: exact,
          distancia_km: exact ? 0 : proxDist,
          destino_label: buildEdgeDestinoLabel(intencao, to, exact, proxDist),
          target_em_destaque: to.em_destaque,
        });
      }
    }

    const edges = [...edgeByToId.values()];
    edges.sort((a, b) => {
      if (a.exato !== b.exato) return a.exato ? -1 : 1;
      if (a.prioridade !== b.prioridade) return a.prioridade - b.prioridade;
      return (a.distancia_km || 0) - (b.distancia_km || 0);
    });

    adjacency.set(from.id, edges);
  }

  return { nodeById, adjacency, indices };
}

function normalizeCycleKey(participantIds) {
  const core = participantIds.slice(0, -1);
  if (core.length === 0) return '';
  const rotations = [];
  for (let i = 0; i < core.length; i++) {
    const rotated = [...core.slice(i), ...core.slice(0, i)];
    rotations.push(rotated.join('-'));
  }
  rotations.sort();
  return rotations[0];
}

function findCyclesForUser(userId, adjacency, maxSize = MAX_CYCLE_SIZE) {
  const cycles = [];
  const seen = new Set();
  const path = [userId];
  const edges = [];

  function dfs(node, depth) {
    if (cycles.length >= MAX_CYCLES) return;
    if (depth >= maxSize) return;

    for (const edge of adjacency.get(node) || []) {
      if (edge.toId === userId && depth >= 1) {
        const participantIds = [...path, userId];
        const key = normalizeCycleKey(participantIds);
        if (!seen.has(key)) {
          seen.add(key);
          cycles.push({
            participantIds,
            edges: [...edges, edge],
            tamanho: participantIds.length - 1,
          });
        }
        continue;
      }

      if (path.includes(edge.toId)) continue;

      path.push(edge.toId);
      edges.push(edge);
      dfs(edge.toId, depth + 1);
      path.pop();
      edges.pop();
    }
  }

  dfs(userId, 0);
  return cycles;
}

function mapNodePublic(node, ocultarDados = false) {
  const hidden = node.ocultar_no_mapa && ocultarDados;
  return {
    id: node.id,
    nome: hidden ? 'Usuário não identificado' : node.nome,
    qso: hidden ? null : node.qso,
    forca_sigla: node.forca_sigla,
    forca_nome: node.forca_nome,
    unidade_atual: node.unidade_atual,
    municipio_atual: node.municipio_atual,
    estado_atual: node.estado_atual,
    posto_graduacao_nome: node.posto_graduacao_nome,
    ocultar_no_mapa: node.ocultar_no_mapa,
    em_destaque: node.em_destaque,
  };
}

function formatLocalizacao(node) {
  if (!node) return 'local não informado';
  const partes = [];
  if (node.municipio_atual) {
    partes.push(
      node.estado_atual
        ? `${node.municipio_atual}-${node.estado_atual}`
        : node.municipio_atual
    );
  }
  if (node.unidade_atual) partes.push(node.unidade_atual);
  return partes.length > 0 ? partes.join(', ') : 'local não informado';
}

function buildEdgeDestinoLabel(intencao, to, exact, proxDist) {
  if (exact) {
    return intencao.destino_label || formatLocalizacao(to);
  }
  return formatLocalizacao(to);
}

function buildResumoParticipante(node, edgeDestinoLabel, edge, nodeById) {
  const nome = node?.ocultar_no_mapa ? 'Usuário não identificado' : node?.nome || 'Usuário';
  const origem = formatLocalizacao(node);
  let destino = edgeDestinoLabel || 'destino não informado';
  if (edge && !edge.exato && edge.toId && nodeById) {
    const destNode = nodeById.get(edge.toId);
    destino = destNode ? formatLocalizacao(destNode) : (edge.destino_label || destino);
  } else if (edge?.destino_label) {
    destino = edge.destino_label;
  }
  return `${nome}: está em ${origem} e vai para ${destino}`;
}

function buildFluxoDescriptions(cycle, nodeById) {
  return cycle.edges.map((edge) => {
    const from = nodeById.get(edge.fromId);
    return buildResumoParticipante(from, edge.destino_label, edge, nodeById);
  });
}

function filterAdjacency(adjacency, allowedIds) {
  const filtered = new Map();
  for (const fromId of allowedIds) {
    const edges = (adjacency.get(fromId) || []).filter((e) => allowedIds.has(e.toId));
    if (edges.length > 0) {
      filtered.set(fromId, edges);
    }
  }
  return filtered;
}

function findMatchesForUser(userNode, scopedNodes, globalAdjacency = null) {
  const nodesForGraph = [
    userNode,
    ...scopedNodes.filter((n) => n.id !== userNode.id),
  ];
  const allowedIds = new Set(nodesForGraph.map((n) => n.id));

  const buildStart = Date.now();
  let nodeById;
  let adjacency;

  if (globalAdjacency) {
    nodeById = new Map(nodesForGraph.map((n) => [n.id, n]));
    adjacency = filterAdjacency(globalAdjacency, allowedIds);
  } else {
    const built = buildEdges(nodesForGraph);
    nodeById = built.nodeById;
    adjacency = built.adjacency;
  }

  const build_ms = Date.now() - buildStart;
  const userId = userNode.id;

  const directas = [];
  const directasSeen = new Set();

  for (const edgeAB of adjacency.get(userId) || []) {
    const edgeBA = (adjacency.get(edgeAB.toId) || []).find((e) => e.toId === userId);
    if (!edgeBA) continue;

    const key = [userId, edgeAB.toId].sort((a, b) => a - b).join('-');
    if (directasSeen.has(key)) continue;
    directasSeen.add(key);

    const target = nodeById.get(edgeAB.toId);
    directas.push({
      tipo: edgeAB.exato && edgeBA.exato ? 'DIRETA' : 'PROXIMA',
      score: scoreDirectMatch(edgeAB, edgeBA),
      ...mapNodePublic(target),
      descricao_interesse: `Match mútuo (P${edgeAB.prioridade}↔P${edgeBA.prioridade})${
        edgeAB.exato && edgeBA.exato ? '' : ' por proximidade'
      }`,
      distancia_km: Math.max(edgeAB.distancia_km || 0, edgeBA.distancia_km || 0) || null,
      prioridades: { minha: edgeAB.prioridade, dele: edgeBA.prioridade },
    });
  }

  const interessados = [];
  const interessadosSeen = new Set();
  const directPartnerIds = new Set(directas.map((d) => d.id));

  for (const node of scopedNodes) {
    if (node.id === userId || directPartnerIds.has(node.id)) continue;
    for (const edge of adjacency.get(node.id) || []) {
      if (edge.toId !== userId) continue;
      if (interessadosSeen.has(node.id)) break;
      interessadosSeen.add(node.id);
      interessados.push({
        tipo: 'INTERESSADO',
        score: scoreInteressado(edge),
        ...mapNodePublic(node),
        descricao_interesse: `Quer sua região (prioridade ${edge.prioridade})${
          edge.exato ? '' : ` — ~${edge.distancia_km} km`
        }`,
        distancia_km: edge.distancia_km || null,
      });
      break;
    }
  }

  const cyclesStart = Date.now();
  const rawCycles = findCyclesForUser(userId, adjacency);
  const cycles_ms = Date.now() - cyclesStart;

  const ciclos = rawCycles.map((cycle) => {
    const participantes = cycle.participantIds.slice(0, -1).map((id, index) => {
      const node = nodeById.get(id);
      const edge = cycle.edges[index];
      return {
        ...mapNodePublic(node),
        descricao_resumo: buildResumoParticipante(node, edge?.destino_label, edge, nodeById),
      };
    });
    const fluxo = buildFluxoDescriptions(cycle, nodeById);
    const maxDist = Math.max(...cycle.edges.map((e) => e.distancia_km || 0), 0);

    return {
      tamanho: cycle.tamanho,
      score: scoreCycle(cycle.edges, cycle.tamanho),
      por_aproximacao: cycle.edges.some((e) => !e.exato),
      distancia_km: maxDist || null,
      participantes,
      fluxo,
      fluxo_texto: fluxo,
    };
  });

  const triangulares = ciclos
    .filter((c) => c.tamanho === 3)
    .map((c) => ({
      score: c.score,
      policialB: c.participantes[1],
      policialC: c.participantes[2],
      fluxo: {
        a_para_b: c.fluxo[0],
        b_para_c: c.fluxo[1],
        c_para_a: c.fluxo[2],
      },
      distancia_km: c.distancia_km,
      por_aproximacao: c.por_aproximacao,
    }));

  const ciclosN = ciclos.filter((c) => c.tamanho >= 4);

  const proximas = directas.filter((d) => d.tipo === 'PROXIMA');
  const diretas = directas.filter((d) => d.tipo === 'DIRETA');

  const edgeCount = countAdjacencyEdges(adjacency);

  const bucketDiretas = sliceRankedBucket(diretas, MAX_DIRECTAS);
  const bucketProximas = sliceRankedBucket(proximas, MAX_DIRECTAS);
  const bucketInteressados = sliceRankedBucket(interessados, MAX_INTERESSADOS);
  const bucketTriangulares = sliceRankedBucket(triangulares, MAX_CYCLES);
  const bucketCiclos = sliceRankedBucket(ciclosN, MAX_CYCLES);

  return {
    diretas: bucketDiretas.items,
    proximas: bucketProximas.items,
    interessados: bucketInteressados.items,
    triangulares: bucketTriangulares.items,
    ciclos_n: bucketCiclos.items,
    bucket_meta: {
      diretas: bucketMetaFromSlice(bucketDiretas),
      proximas: bucketMetaFromSlice(bucketProximas),
      interessados: bucketMetaFromSlice(bucketInteressados),
      triangulares: bucketMetaFromSlice(bucketTriangulares),
      ciclos_n: bucketMetaFromSlice(bucketCiclos),
    },
    graph_stats: {
      nodes: nodesForGraph.length,
      edges: edgeCount,
      build_ms,
      cycles_ms,
      cycles_found: rawCycles.length,
    },
  };
}

function sliceRankedBucket(items, max) {
  const sorted = sortByScoreDesc(items || []);
  const available_count = sorted.length;
  const truncated = available_count > max;
  const sliced = sorted.slice(0, max);
  return {
    items: sliced,
    available_count,
    returned_count: sliced.length,
    truncated,
  };
}

function bucketMetaFromSlice(sliceResult) {
  return {
    returned_count: sliceResult.returned_count,
    available_count: sliceResult.available_count,
    truncated: sliceResult.truncated,
  };
}

function filterNodesForUser(userNode, allNodes) {
  return allNodes.filter((node) => {
    if (node.id === userNode.id) return false;
    if (userNode.lotacao_interestadual) {
      return node.tipo_permuta === userNode.tipo_permuta;
    }
    return node.forca_id === userNode.forca_id;
  });
}

module.exports = {
  MAX_CYCLE_SIZE,
  MAX_CYCLES,
  MAX_DIRECTAS,
  MAX_INTERESSADOS,
  sliceRankedBucket,
  bucketMetaFromSlice,
  buildEdges,
  buildLocationIndices,
  collectCandidatesForIntention,
  countAdjacencyEdges,
  filterAdjacency,
  isSameStateLotacao,
  isEstadoIntentionAllowed,
  eligibleIntentions,
  intentionTargetsLocation,
  intentionProximityToLocation,
  findCyclesForUser,
  findMatchesForUser,
  filterNodesForUser,
  mapNodePublic,
  normalizeCycleKey,
};
