// /src/modules/mapa/mapa.repository.js

const db = require('../../config/db');

// Função auxiliar para construir a cláusula WHERE dinamicamente
const buildWhereClause = (filters) => {
  const { estado_id, forca_id } = filters;
  let whereClause = '';
  const params = [];

  if (forca_id) {
    whereClause += ' AND p.forca_id = ?';
    params.push(forca_id);
  }
  if (estado_id) {
    whereClause += ' AND m.estado_id = ?';
    params.push(estado_id);
  }
  return { whereClause, params };
};

class MapaRepository {
  async findOrigens(filters) {
    const { whereClause, params } = buildWhereClause(filters);
    const query = `
        SELECT m.id, m.nome, m.latitude, m.longitude, COUNT(DISTINCT p.id) as contagem
        FROM municipios m
        JOIN unidades u ON u.municipio_id = m.id
        JOIN policiais p ON p.unidade_atual_id = u.id
        WHERE m.latitude IS NOT NULL AND m.longitude IS NOT NULL ${whereClause}
        GROUP BY m.id, m.nome, m.latitude, m.longitude;
    `;
    const [origens] = await db.query(query, params);
    return origens;
  }

  async findDestinos(filters) {
    const { whereClause, params } = buildWhereClause(filters);
    const query = `
        SELECT m.id, m.nome, m.latitude, m.longitude, COUNT(DISTINCT i.id) as contagem
        FROM municipios m
        JOIN intencoes i ON i.municipio_id = m.id
        JOIN policiais p ON i.policial_id = p.id
        WHERE i.tipo_intencao = 'MUNICIPIO' AND m.latitude IS NOT NULL AND m.longitude IS NOT NULL ${whereClause}
        GROUP BY m.id, m.nome, m.latitude, m.longitude;
    `;
    const [destinos] = await db.query(query, params);
    return destinos;
  }

  async findSaindoDetails(filters) {
    const { id, forca_id } = filters;
    const params = [id];
    let query = `
        SELECT p.nome as policial_nome, f.sigla as forca_sigla, u.nome as unidade_nome
        FROM policiais p
        JOIN forcas_policiais f ON p.forca_id = f.id
        JOIN unidades u ON p.unidade_atual_id = u.id
        WHERE u.municipio_id = ?
    `;
    if (forca_id) {
      query += ' AND p.forca_id = ?';
      params.push(forca_id);
    }
    const [details] = await db.query(query, params);
    return details;
  }

  async findVindoDetails(filters) {
    const { id, forca_id } = filters;
    const params = [id];
    let query = `
        SELECT p.nome as policial_nome, f.sigla as forca_sigla, u.nome as unidade_nome
        FROM intencoes i
        JOIN policiais p ON i.policial_id = p.id
        JOIN forcas_policiais f ON p.forca_id = f.id
        LEFT JOIN unidades u ON p.unidade_atual_id = u.id
        WHERE i.tipo_intencao = 'MUNICIPIO' AND i.municipio_id = ?
    `;
    if (forca_id) {
      query += ' AND p.forca_id = ?';
      params.push(forca_id);
    }
    const [details] = await db.query(query, params);
    return details;
  }
}

module.exports = new MapaRepository();