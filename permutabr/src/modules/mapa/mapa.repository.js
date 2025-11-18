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
        SELECT 
          p.id as policial_id,
          CASE WHEN p.ocultar_no_mapa = 0 THEN p.nome ELSE 'Usuário não identificado' END as policial_nome, 
          CASE WHEN p.ocultar_no_mapa = 0 THEN p.qso ELSE NULL END as qso,
          p.ocultar_no_mapa,
          f.sigla as forca_sigla, 
          u.nome as unidade_nome,
          m.nome as municipio_atual,
          e.sigla as estado_atual,
          GROUP_CONCAT(
            DISTINCT CASE 
              WHEN i.tipo_intencao = 'UNIDADE' THEN CONCAT('Unidade: ', u2.nome)
              WHEN i.tipo_intencao = 'MUNICIPIO' THEN CONCAT('Município: ', m2.nome, '-', e2.sigla)
              WHEN i.tipo_intencao = 'ESTADO' THEN CONCAT('Estado: ', e2.sigla)
            END
            ORDER BY i.prioridade
            SEPARATOR ' | '
          ) as destinos_desejados
        FROM policiais p
        JOIN forcas_policiais f ON p.forca_id = f.id
        JOIN unidades u ON p.unidade_atual_id = u.id
        JOIN municipios m ON u.municipio_id = m.id
        JOIN estados e ON m.estado_id = e.id
        LEFT JOIN intencoes i ON i.policial_id = p.id
        LEFT JOIN unidades u2 ON i.unidade_id = u2.id
        LEFT JOIN municipios m2 ON i.municipio_id = m2.id OR u2.municipio_id = m2.id
        LEFT JOIN estados e2 ON i.estado_id = e2.id OR m2.estado_id = e2.id
        WHERE u.municipio_id = ? AND p.status_verificacao = 'VERIFICADO'
    `;
    if (forca_id) {
      query += ' AND p.forca_id = ?';
      params.push(forca_id);
    }
    query += ' GROUP BY p.id, p.nome, p.qso, f.sigla, u.nome, m.nome, e.sigla';
    const [details] = await db.query(query, params);
    return details;
  }

  async findVindoDetails(filters) {
    const { id, forca_id } = filters;
    const params = [id];
    let query = `
        SELECT 
          p.id as policial_id,
          CASE WHEN p.ocultar_no_mapa = 0 THEN p.nome ELSE 'Usuário não identificado' END as policial_nome,
          CASE WHEN p.ocultar_no_mapa = 0 THEN p.qso ELSE NULL END as qso,
          p.ocultar_no_mapa,
          f.sigla as forca_sigla, 
          u.nome as unidade_nome,
          m.nome as municipio_atual,
          e.sigla as estado_atual,
          m_dest.nome as municipio_desejado,
          e_dest.sigla as estado_desejado
        FROM intencoes i
        JOIN policiais p ON i.policial_id = p.id
        JOIN forcas_policiais f ON p.forca_id = f.id
        LEFT JOIN unidades u ON p.unidade_atual_id = u.id
        LEFT JOIN municipios m ON u.municipio_id = m.id
        LEFT JOIN estados e ON m.estado_id = e.id
        JOIN municipios m_dest ON i.municipio_id = m_dest.id
        JOIN estados e_dest ON m_dest.estado_id = e_dest.id
        WHERE i.tipo_intencao = 'MUNICIPIO' AND i.municipio_id = ? 
          AND p.status_verificacao = 'VERIFICADO'
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