// /src/modules/mapa/mapa.service.js

const mapaRepository = require('./mapa.repository');
const mapaCacheRepository = require('./mapa.cache.repository');
const perfLogger = require('../../core/utils/performance-logger');

class MapaService {
  async _computeMapData(filters) {
    const { tipo } = filters;
    let pontos = [];

    if (tipo === 'saindo') {
      pontos = await mapaRepository.findOrigens(filters);
    } else if (tipo === 'vindo') {
      pontos = await mapaRepository.findDestinos(filters);
    } else if (tipo === 'balanco') {
      const [origens, destinos] = await Promise.all([
        mapaRepository.findOrigens(filters),
        mapaRepository.findDestinos(filters),
      ]);

      const mapaAgregado = new Map();

      for (const o of origens) {
        mapaAgregado.set(o.id, { ...o, saindo: o.contagem, vindo: 0 });
      }

      for (const d of destinos) {
        if (mapaAgregado.has(d.id)) {
          mapaAgregado.get(d.id).vindo = d.contagem;
        } else {
          mapaAgregado.set(d.id, { ...d, saindo: 0, vindo: d.contagem });
        }
      }

      pontos = Array.from(mapaAgregado.values()).map((p) => ({
        ...p,
        balanco: p.vindo - p.saindo,
        volume: p.vindo + p.saindo,
      }));
    }

    return { pontos };
  }

  async getMapData(filters) {
    const t0 = Date.now();

    await mapaCacheRepository.purgeExpired();
    const cached = await mapaCacheRepository.getSnapshot(filters);

    if (cached) {
      const elapsed = Date.now() - t0;
      perfLogger.record('MAPA', 'map_data', {
        cache_hit: true,
        ms: elapsed,
        tipo: filters.tipo,
        pontos: cached.data.pontos?.length ?? 0,
      });
      return {
        ...cached.data,
        cache: {
          hit: true,
          computed_at: cached.computed_at,
          expires_at: cached.expires_at,
        },
      };
    }

    const data = await this._computeMapData(filters);
    const meta = await mapaCacheRepository.saveSnapshot(filters, data);
    const elapsed = Date.now() - t0;

    perfLogger.record('MAPA', 'map_data', {
      cache_hit: false,
      ms: elapsed,
      tipo: filters.tipo,
      pontos: data.pontos?.length ?? 0,
    });

    return {
      ...data,
      cache: {
        hit: false,
        computed_at: new Date(),
        expires_at: meta.expires_at,
      },
    };
  }

  async getMunicipioDetails(filters) {
    const t0 = Date.now();
    const { tipo } = filters;
    const detailsFilters = {
      ...filters,
      limit: Math.min(parseInt(filters.limit, 10) || 100, 100),
    };

    const result =
      tipo === 'saindo'
        ? await mapaRepository.findSaindoDetails(detailsFilters)
        : await mapaRepository.findVindoDetails(detailsFilters);

    perfLogger.record('MAPA', 'municipio_details', {
      ms: Date.now() - t0,
      tipo,
      municipio_id: filters.id,
      rows: result.length,
    });

    return result;
  }
}

module.exports = new MapaService();
