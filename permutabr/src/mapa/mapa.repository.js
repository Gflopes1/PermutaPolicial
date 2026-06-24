// /src/modules/mapa/mapa.repository.js

const db = require('../../config/db');

const VERIFICADO = "p.status_verificacao = 'VERIFICADO'";

const buildWhereClause = (filters) => {
  const { estado_id, forca_id } = filters;
  let whereClause = '';
  const params = [];

  if (forca_id) {
    whereClause += ' AND base.forca_id = ?';
    params.push(forca_id);
  }
  if (estado_id) {
    whereClause += ' AND m.estado_id = ?';
    params.push(estado_id);
  }
  return { whereClause, params };
};

const buildDetailsEstadoClause = (estado_id) => {
  if (!estado_id) return { clause: '', params: [] };
  return {
    clause: ' AND m_ref.estado_id = ?',
    params: [estado_id],
  };
};

/**
 * Subquery base: resolve município atual via COALESCE(municipio_atual, unidade.municipio)
 * em vez de OR/EXISTS no JOIN — permite uso de índices em resolved_municipio_id.
 */
const RESOLVED_ORIGEM_SUBQUERY = `
  SELECT
    i.policial_id,
    p.forca_id,
    COALESCE(i.municipio_atual_id, u.municipio_id) AS resolved_municipio_id
  FROM intencoes i
  JOIN policiais p ON i.policial_id = p.id
  LEFT JOIN unidades u ON u.id = i.unidade_atual_id
  WHERE ${VERIFICADO}
    AND (i.unidade_atual_id IS NOT NULL OR i.municipio_atual_id IS NOT NULL)
    AND COALESCE(i.municipio_atual_id, u.municipio_id) IS NOT NULL
`;

class MapaRepository {
  async findOrigens(filters) {
    const { whereClause, params } = buildWhereClause(filters);
    const query = `
        SELECT m.id, m.nome, m.latitude, m.longitude, COUNT(DISTINCT base.policial_id) AS contagem
        FROM (${RESOLVED_ORIGEM_SUBQUERY}) base
        JOIN municipios m ON m.id = base.resolved_municipio_id
        WHERE m.latitude IS NOT NULL AND m.longitude IS NOT NULL
        ${whereClause}
        GROUP BY m.id, m.nome, m.latitude, m.longitude;
    `;
    const [origens] = await db.execute(query, params);
    return origens;
  }

  async findDestinos(filters) {
    const { whereClause, params } = buildWhereClause(filters);
    const query = `
        SELECT m.id, m.nome, m.latitude, m.longitude, COUNT(DISTINCT i.policial_id) AS contagem
        FROM municipios m
        JOIN intencoes i ON i.municipio_id = m.id
        JOIN policiais p ON i.policial_id = p.id
        LEFT JOIN unidades u ON u.id = i.unidade_atual_id
        WHERE i.tipo_intencao = 'MUNICIPIO'
          AND m.latitude IS NOT NULL AND m.longitude IS NOT NULL
          AND ${VERIFICADO}
          AND (i.unidade_atual_id IS NOT NULL OR i.municipio_atual_id IS NOT NULL)
          ${whereClause.replace(/base\.forca_id/g, 'p.forca_id')}
        GROUP BY m.id, m.nome, m.latitude, m.longitude;
    `;
    const [destinos] = await db.execute(query, params);
    return destinos;
  }

  async findSaindoDetails(filters) {
    const { id, forca_id, estado_id, limit = 100 } = filters;
    const { clause: estadoClause, params: estadoParams } = buildDetailsEstadoClause(estado_id);
    const params = [id, id, ...estadoParams];
    let query = `
        SELECT DISTINCT
          p.id as policial_id,
          CASE WHEN p.ocultar_no_mapa = 0 THEN p.nome ELSE 'Usuário não identificado' END as policial_nome, 
          CASE WHEN p.ocultar_no_mapa = 0 THEN p.qso ELSE NULL END as qso,
          p.ocultar_no_mapa,
          (p.destaque_ate IS NOT NULL AND p.destaque_ate > NOW()) as em_destaque,
          f.sigla as forca_sigla, 
          u_atual.nome as unidade_nome,
          COALESCE(m_direto.nome, m_unidade.nome) as municipio_atual,
          COALESCE(e_direto.sigla, e_unidade.sigla) as estado_atual,
          (
            SELECT GROUP_CONCAT(
              CONCAT(
                CASE i2.tipo_intencao
                  WHEN 'UNIDADE' THEN CONCAT('Unidade: ', COALESCE(u2.nome, 'não informada'))
                  WHEN 'MUNICIPIO' THEN CONCAT(
                    'Município: ',
                    COALESCE(m2.nome, 'não informado'),
                    CASE WHEN e2.sigla IS NOT NULL THEN CONCAT('-', e2.sigla) ELSE '' END
                  )
                  WHEN 'ESTADO' THEN CONCAT('Estado: ', COALESCE(e2.sigla, 'não informado'))
                END,
                CASE
                  WHEN i2.raio_km IS NOT NULL AND i2.raio_km > 0
                  THEN CONCAT(' (±', i2.raio_km, ' km)')
                  ELSE ''
                END
              )
              ORDER BY i2.prioridade
              SEPARATOR ' | '
            )
            FROM intencoes i2
            LEFT JOIN unidades u2 ON i2.unidade_id = u2.id
            LEFT JOIN municipios m2 ON i2.municipio_id = m2.id
            LEFT JOIN estados e2 ON e2.id = COALESCE(m2.estado_id, i2.estado_id)
            WHERE i2.policial_id = p.id
              AND i2.tipo_intencao IN ('UNIDADE', 'MUNICIPIO', 'ESTADO')
          ) as destinos_desejados
        FROM (
          SELECT DISTINCT i.policial_id, 
            MIN(i.prioridade) as min_prioridade
          FROM intencoes i
          LEFT JOIN unidades u ON u.id = i.unidade_atual_id
          WHERE COALESCE(i.municipio_atual_id, u.municipio_id) = ?
          AND (i.unidade_atual_id IS NOT NULL OR i.municipio_atual_id IS NOT NULL)
          GROUP BY i.policial_id
        ) as policiais_municipio
        JOIN intencoes i ON i.policial_id = policiais_municipio.policial_id 
          AND i.prioridade = policiais_municipio.min_prioridade
        JOIN policiais p ON i.policial_id = p.id
        JOIN forcas_policiais f ON p.forca_id = f.id
        JOIN municipios m_ref ON m_ref.id = ?
        LEFT JOIN unidades u_atual ON i.unidade_atual_id = u_atual.id
        LEFT JOIN municipios m_direto ON i.municipio_atual_id = m_direto.id
        LEFT JOIN estados e_direto ON m_direto.estado_id = e_direto.id
        LEFT JOIN municipios m_unidade ON u_atual.municipio_id = m_unidade.id
        LEFT JOIN estados e_unidade ON m_unidade.estado_id = e_unidade.id
        WHERE ${VERIFICADO}
        ${estadoClause}
    `;
    if (forca_id) {
      query += ' AND p.forca_id = ?';
      params.push(forca_id);
    }
    query += ' ORDER BY em_destaque DESC LIMIT ?';
    params.push(Number(limit));
    const [details] = await db.execute(query, params);
    return details;
  }

  async findVindoDetails(filters) {
    const { id, forca_id, estado_id, limit = 100 } = filters;
    const { clause: estadoClause, params: estadoParams } = buildDetailsEstadoClause(estado_id);
    const params = [id, id, id, ...estadoParams];
    let query = `
        SELECT DISTINCT
          p.id as policial_id,
          CASE WHEN p.ocultar_no_mapa = 0 THEN p.nome ELSE 'Usuário não identificado' END as policial_nome,
          CASE WHEN p.ocultar_no_mapa = 0 THEN p.qso ELSE NULL END as qso,
          p.ocultar_no_mapa,
          (p.destaque_ate IS NOT NULL AND p.destaque_ate > NOW()) as em_destaque,
          f.sigla as forca_sigla, 
          u_atual.nome as unidade_nome,
          COALESCE(m_atual_direto.nome, m_atual_unidade.nome) as municipio_atual,
          COALESCE(e_atual_direto.sigla, e_atual_unidade.sigla) as estado_atual,
          m_dest.nome as municipio_desejado,
          e_dest.sigla as estado_desejado,
          (
            SELECT GROUP_CONCAT(
              CONCAT(
                CASE i2.tipo_intencao
                  WHEN 'UNIDADE' THEN CONCAT('Unidade: ', COALESCE(u2.nome, 'não informada'))
                  WHEN 'MUNICIPIO' THEN CONCAT(
                    'Município: ',
                    COALESCE(m2.nome, 'não informado'),
                    CASE WHEN e2.sigla IS NOT NULL THEN CONCAT('-', e2.sigla) ELSE '' END
                  )
                  WHEN 'ESTADO' THEN CONCAT('Estado: ', COALESCE(e2.sigla, 'não informado'))
                END,
                CASE
                  WHEN i2.raio_km IS NOT NULL AND i2.raio_km > 0
                  THEN CONCAT(' (±', i2.raio_km, ' km)')
                  ELSE ''
                END
              )
              ORDER BY i2.prioridade
              SEPARATOR ' | '
            )
            FROM intencoes i2
            LEFT JOIN unidades u2 ON i2.unidade_id = u2.id
            LEFT JOIN municipios m2 ON i2.municipio_id = m2.id
            LEFT JOIN estados e2 ON e2.id = COALESCE(m2.estado_id, i2.estado_id)
            WHERE i2.policial_id = p.id
              AND i2.tipo_intencao IN ('UNIDADE', 'MUNICIPIO', 'ESTADO')
          ) as destinos_desejados
        FROM (
          SELECT DISTINCT i.policial_id, MIN(i.prioridade) as min_prioridade
          FROM intencoes i
          WHERE i.tipo_intencao = 'MUNICIPIO' AND i.municipio_id = ?
          AND (i.unidade_atual_id IS NOT NULL OR i.municipio_atual_id IS NOT NULL)
          GROUP BY i.policial_id
        ) as policiais_destino
        JOIN intencoes i ON i.policial_id = policiais_destino.policial_id
          AND i.prioridade = policiais_destino.min_prioridade
          AND i.tipo_intencao = 'MUNICIPIO' AND i.municipio_id = ?
        JOIN policiais p ON i.policial_id = p.id
        JOIN forcas_policiais f ON p.forca_id = f.id
        JOIN municipios m_dest ON i.municipio_id = m_dest.id
        JOIN estados e_dest ON m_dest.estado_id = e_dest.id
        JOIN municipios m_ref ON m_ref.id = ?
        LEFT JOIN unidades u_atual ON i.unidade_atual_id = u_atual.id
        LEFT JOIN municipios m_atual_direto ON i.municipio_atual_id = m_atual_direto.id
        LEFT JOIN estados e_atual_direto ON m_atual_direto.estado_id = e_atual_direto.id
        LEFT JOIN municipios m_atual_unidade ON u_atual.municipio_id = m_atual_unidade.id
        LEFT JOIN estados e_atual_unidade ON m_atual_unidade.estado_id = e_atual_unidade.id
        WHERE ${VERIFICADO}
        ${estadoClause}
    `;
    if (forca_id) {
      query += ' AND p.forca_id = ?';
      params.push(forca_id);
    }
    query += ' ORDER BY em_destaque DESC LIMIT ?';
    params.push(Number(limit));
    const [details] = await db.execute(query, params);
    return details;
  }
}

module.exports = new MapaRepository();
