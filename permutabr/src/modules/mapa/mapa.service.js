// /src/modules/mapa/mapa.service.js

const mapaRepository = require('./mapa.repository');

class MapaService {
  async getMapData(filters) {
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

      // Adiciona quem quer sair (negativo)
      for (const o of origens) {
        mapaAgregado.set(o.id, { ...o, saindo: o.contagem, vindo: 0 });
      }

      // Adiciona/Atualiza quem quer vir (positivo)
      for (const d of destinos) {
        if (mapaAgregado.has(d.id)) {
          mapaAgregado.get(d.id).vindo = d.contagem;
        } else {
          mapaAgregado.set(d.id, { ...d, saindo: 0, vindo: d.contagem });
        }
      }

      // Calcula o balanço e o volume total para cada ponto
      pontos = Array.from(mapaAgregado.values()).map(p => ({
        ...p,
        balanco: p.vindo - p.saindo,
        volume: p.vindo + p.saindo,
      }));
    }

    return { pontos };
  }

  async getMunicipioDetails(filters) {
    const { tipo } = filters;
    if (tipo === 'saindo') {
      return mapaRepository.findSaindoDetails(filters);
    }
    // 'vindo'
    return mapaRepository.findVindoDetails(filters);
  }
}

module.exports = new MapaService();