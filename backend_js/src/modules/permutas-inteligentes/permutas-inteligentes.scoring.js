// Scoring heurístico (sem ML) para o motor experimental

const PRIORITY_WEIGHT = { 1: 100, 2: 60, 3: 30 };

function priorityWeight(prioridade) {
  return PRIORITY_WEIGHT[prioridade] ?? 20;
}

function scoreDirectMatch(edgeTo, edgeBack) {
  let score = 1000;
  score += priorityWeight(edgeTo.prioridade);
  score += priorityWeight(edgeBack.prioridade);
  if (edgeTo.exato) score += 50;
  if (edgeBack.exato) score += 50;
  score -= (edgeTo.distancia_km || 0) * 2;
  score -= (edgeBack.distancia_km || 0) * 2;
  if (edgeTo.target_em_destaque || edgeBack.target_em_destaque) score += 25;
  return Math.round(score * 100) / 100;
}

function scoreInteressado(edge) {
  let score = 220;
  score += priorityWeight(edge.prioridade);
  if (edge.exato) score += 40;
  score -= (edge.distancia_km || 0) * 1.5;
  if (edge.target_em_destaque) score += 15;
  return Math.round(score * 100) / 100;
}

// Score base 880 pressupõe ciclo com todas as arestas exatas.
function scoreCycle(cycleEdges, participantCount) {
  const n = participantCount;
  let score = 880 - Math.max(0, n - 3) * 45;
  const proxEdges = cycleEdges.filter((e) => !e.exato).length;
  score -= (proxEdges / cycleEdges.length) * 80; // penalidade por proximidade no ciclo

  for (const edge of cycleEdges) {
    score += priorityWeight(edge.prioridade) / n;
    if (edge.exato) score += 25;
    score -= (edge.distancia_km || 0) * 1.2;
    if (edge.target_em_destaque) score += 10 / n;
  }

  const allExact = cycleEdges.every((e) => e.exato);
  if (allExact) score += 40;

  return Math.round(score * 100) / 100;
}

function sortByScoreDesc(items) {
  return [...items].sort((a, b) => (b.score ?? 0) - (a.score ?? 0));
}

module.exports = {
  PRIORITY_WEIGHT,
  priorityWeight,
  scoreDirectMatch,
  scoreInteressado,
  scoreCycle,
  sortByScoreDesc,
};
