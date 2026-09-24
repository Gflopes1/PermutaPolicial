const ApiError = require('../../core/utils/ApiError');
const { haversineKm } = require('../../core/utils/geo.utils');
const { getOrBuildGraphSnapshot } = require('../permutas-inteligentes/permutas-inteligentes.service');
const {
  findMatchesForUser,
  filterNodesForUser,
  eligibleIntentions,
  intentionTargetsLocation,
  intentionProximityToLocation,
} = require('../permutas-inteligentes/permutas-inteligentes.graph');
const previewRepository = require('./permutas-preview.repository');

const GHOST_PREVIEW_ID = -999999;
const DEFAULT_RAIO_KM = 50;
const PREVIEW_CACHE_TTL_MS = 15 * 60 * 1000;
const previewCache = new Map();

function cacheKey(payload) {
  return [
    payload.forca_id,
    payload.municipio_atual_id,
    payload.municipio_destino_id,
    payload.raio_km,
  ].join(':');
}

function getCached(key) {
  const entry = previewCache.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expires_at) {
    previewCache.delete(key);
    return null;
  }
  return entry.data;
}

function setCache(key, data) {
  previewCache.set(key, { data, expires_at: Date.now() + PREVIEW_CACHE_TTL_MS });
  if (previewCache.size > 500) {
    const oldest = previewCache.keys().next().value;
    previewCache.delete(oldest);
  }
}

function parseCoords(municipio) {
  const lat = municipio.latitude != null ? parseFloat(municipio.latitude) : null;
  const lng = municipio.longitude != null ? parseFloat(municipio.longitude) : null;
  return { lat, lng };
}

function buildGhostNode({ forca, municipioAtual, municipioDestino, raioKm }) {
  const { lat, lng } = parseCoords(municipioAtual);
  const destCoords = parseCoords(municipioDestino);

  return {
    id: GHOST_PREVIEW_ID,
    nome: 'Visitante',
    qso: null,
    forca_id: forca.id,
    tipo_permuta: forca.tipo_permuta,
    forca_sigla: forca.sigla,
    forca_nome: forca.nome,
    posto_graduacao_nome: null,
    ocultar_no_mapa: true,
    em_destaque: false,
    lotacao_interestadual: false,
    unidade_atual_id: null,
    municipio_atual_id: municipioAtual.id,
    estado_atual_id: municipioAtual.estado_id,
    unidade_atual: null,
    municipio_atual: municipioAtual.nome,
    estado_atual: municipioAtual.estado_sigla,
    lat,
    lng,
    intencoes: [
      {
        id: -1,
        prioridade: 1,
        tipo_intencao: 'MUNICIPIO',
        estado_id: municipioDestino.estado_id,
        municipio_id: municipioDestino.id,
        unidade_id: null,
        raio_km: raioKm,
        destino_lat: destCoords.lat,
        destino_lng: destCoords.lng,
        destino_label: `${municipioDestino.nome}-${municipioDestino.estado_sigla}`,
      },
    ],
  };
}

function countInteressadosNaRegiao(scopedNodes, municipioAtual, raioKm) {
  const { lat, lng } = parseCoords(municipioAtual);
  if (lat == null || lng == null) return 0;

  const regionTarget = {
    municipio_atual_id: municipioAtual.id,
    unidade_atual_id: null,
    estado_atual_id: municipioAtual.estado_id,
    lat,
    lng,
  };

  let count = 0;

  for (const node of scopedNodes) {
    let interested = false;

    for (const intencao of eligibleIntentions(node.intencoes)) {
      if (intentionTargetsLocation(intencao, regionTarget)) {
        interested = true;
        break;
      }

      if (intentionProximityToLocation(intencao, regionTarget) != null) {
        interested = true;
        break;
      }

      if (intencao.destino_lat != null && intencao.destino_lng != null) {
        const dist = haversineKm(intencao.destino_lat, intencao.destino_lng, lat, lng);
        if (dist != null && dist <= raioKm) {
          interested = true;
          break;
        }
      }
    }

    if (interested) count += 1;
  }

  return count;
}

function countPossiveisPermutas(matches) {
  return (
    (matches.diretas?.length || 0) +
    (matches.proximas?.length || 0) +
    (matches.triangulares?.length || 0) +
    (matches.ciclos_n?.length || 0)
  );
}

const FEDERAL_TIPOS = new Set(['PF', 'PRF', 'PFF']);

async function resolveForca({ forca_id, tipo_permuta, estado_sigla }) {
  if (forca_id) {
    const forca = await previewRepository.findForcaById(forca_id);
    if (!forca) throw new ApiError(400, 'Corporação não encontrada.');
    return forca;
  }

  const tipo = String(tipo_permuta || '').trim().toUpperCase();
  if (!tipo) throw new ApiError(400, 'Informe forca_id ou tipo_permuta.');

  if (FEDERAL_TIPOS.has(tipo)) {
    const forca = await previewRepository.findForcaByTipoPermuta(tipo);
    if (!forca) throw new ApiError(400, 'Corporação não encontrada.');
    return forca;
  }

  const uf = String(estado_sigla || '').trim().toUpperCase();
  if (!uf) {
    throw new ApiError(400, 'Informe o estado (UF) da sua lotação para simular permutas estaduais.');
  }

  const forca = await previewRepository.findForcaByTipoAndEstado(tipo, uf);
  if (!forca) {
    throw new ApiError(
      404,
      `Não encontramos corporação ${tipo} no estado ${uf}. Verifique a UF ou cadastre-se no app.`
    );
  }
  return forca;
}

async function resolveMunicipio({ municipio_id, nome, estado }) {
  if (municipio_id) {
    const m = await previewRepository.findMunicipioById(municipio_id);
    if (!m) throw new ApiError(404, 'Município não encontrado.');
    return m;
  }
  if (nome) {
    const m = await previewRepository.findMunicipioByNome(nome, estado || null);
    if (!m) throw new ApiError(404, 'Município não encontrado. Verifique o nome e a UF.');
    return m;
  }
  throw new ApiError(400, 'Informe municipio_id ou nome do município.');
}

class PermutasPreviewService {
  async simular({
    forca_id,
    tipo_permuta,
    cidade_atual,
    cidade_destino,
    municipio_atual_id,
    municipio_destino_id,
    estado,
    raio_km = DEFAULT_RAIO_KM,
  }) {
    const raioKm = Math.min(Math.max(Number(raio_km) || DEFAULT_RAIO_KM, 10), 500);

    const municipioAtual = await resolveMunicipio({
      municipio_id: municipio_atual_id,
      nome: cidade_atual,
      estado,
    });

    const estadoDestino =
      String(estado || '').trim().toUpperCase() || municipioAtual.estado_sigla;

    const municipioDestino = await resolveMunicipio({
      municipio_id: municipio_destino_id,
      nome: cidade_destino,
      estado: estadoDestino,
    });

    const forca = await resolveForca({
      forca_id,
      tipo_permuta,
      estado_sigla: municipioAtual.estado_sigla,
    });

    const key = cacheKey({
      forca_id: forca.id,
      municipio_atual_id: municipioAtual.id,
      municipio_destino_id: municipioDestino.id,
      raio_km: raioKm,
    });

    const cached = getCached(key);
    if (cached) return { ...cached, cache: { hit: true } };

    let snapshot;
    try {
      snapshot = await getOrBuildGraphSnapshot(false);
    } catch (err) {
      console.error('[preview-simulacao] Falha ao carregar grafo:', err);
      throw new ApiError(503, 'Motor de permutas temporariamente indisponível. Tente novamente em instantes.');
    }

    const ghostNode = buildGhostNode({
      forca,
      municipioAtual,
      municipioDestino,
      raioKm,
    });

    const scopedNodes = filterNodesForUser(ghostNode, snapshot.nodes);
    let matches;
    try {
      matches = findMatchesForUser(ghostNode, scopedNodes, null);
    } catch (err) {
      console.error('[preview-simulacao] Falha ao calcular matches:', err);
      throw new ApiError(503, 'Não foi possível calcular a simulação agora. Tente novamente.');
    }

    const result = {
      possiveis_permutas: countPossiveisPermutas(matches),
      interessados_regiao: countInteressadosNaRegiao(scopedNodes, municipioAtual, raioKm),
      regiao_km: raioKm,
      cache: { hit: false },
    };

    setCache(key, result);
    return result;
  }

  async getPublicStats() {
    return previewRepository.getPublicStats();
  }
}

module.exports = new PermutasPreviewService();
