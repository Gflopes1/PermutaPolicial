// Carrega nós do grafo (todas as intenções por policial)

const db = require('../../config/db');

async function loadGraphNodes() {
  const [rows] = await db.execute(`
    SELECT
      p.id,
      p.nome,
      p.qso,
      p.forca_id,
      p.posto_graduacao_id,
      p.ocultar_no_mapa,
      p.lotacao_interestadual,
      (p.destaque_ate IS NOT NULL AND p.destaque_ate > NOW()) AS em_destaque,
      f.tipo_permuta,
      f.sigla AS forca_sigla,
      f.nome AS forca_nome,
      pg.nome AS posto_graduacao_nome,
      i.id AS intencao_id,
      i.prioridade,
      i.tipo_intencao,
      i.estado_id,
      i.municipio_id,
      i.unidade_id,
      i.unidade_atual_id,
      i.municipio_atual_id,
      i.raio_km,
      COALESCE(i.unidade_atual_id, p.unidade_atual_id) AS resolved_unidade_atual_id,
      COALESCE(i.municipio_atual_id, p.municipio_atual_id) AS resolved_municipio_atual_id,
      u_atual.nome AS unidade_atual,
      COALESCE(m_atual_d.nome, m_atual_u.nome) AS municipio_atual,
      COALESCE(e_atual_d.sigla, e_atual_u.sigla) AS estado_atual,
      COALESCE(m_atual_d.id, m_atual_u.id) AS municipio_atual_id_resolved,
      COALESCE(e_atual_d.id, e_atual_u.id) AS estado_atual_id_resolved,
      COALESCE(m_atual_d.latitude, m_atual_u.latitude) AS lat,
      COALESCE(m_atual_d.longitude, m_atual_u.longitude) AS lng,
      m_dest.nome AS municipio_destino_nome,
      e_dest.sigla AS estado_destino_sigla,
      u_dest.nome AS unidade_destino_nome,
      COALESCE(m_dest.latitude, m_u_dest.latitude) AS destino_lat,
      COALESCE(m_dest.longitude, m_u_dest.longitude) AS destino_lng
    FROM policiais p
    JOIN forcas_policiais f ON p.forca_id = f.id
    LEFT JOIN postos_graduacoes pg ON p.posto_graduacao_id = pg.id
    JOIN intencoes i ON i.policial_id = p.id
    LEFT JOIN unidades u_atual ON u_atual.id = COALESCE(i.unidade_atual_id, p.unidade_atual_id)
    LEFT JOIN municipios m_atual_d ON m_atual_d.id = COALESCE(i.municipio_atual_id, p.municipio_atual_id)
    LEFT JOIN estados e_atual_d ON e_atual_d.id = m_atual_d.estado_id
    LEFT JOIN municipios m_atual_u ON m_atual_u.id = u_atual.municipio_id
    LEFT JOIN estados e_atual_u ON e_atual_u.id = m_atual_u.estado_id
    LEFT JOIN municipios m_dest ON m_dest.id = i.municipio_id
    LEFT JOIN estados e_dest ON e_dest.id = COALESCE(m_dest.estado_id, i.estado_id)
    LEFT JOIN unidades u_dest ON u_dest.id = i.unidade_id
    LEFT JOIN municipios m_u_dest ON m_u_dest.id = u_dest.municipio_id
    WHERE p.status_verificacao = 'VERIFICADO'
      AND i.tipo_intencao IN ('UNIDADE', 'MUNICIPIO', 'ESTADO')
      AND (
        COALESCE(i.unidade_atual_id, p.unidade_atual_id) IS NOT NULL
        OR COALESCE(i.municipio_atual_id, p.municipio_atual_id) IS NOT NULL
      )
    ORDER BY p.id ASC, i.prioridade ASC
  `);

  const byId = new Map();

  for (const row of rows) {
    if (!byId.has(row.id)) {
      byId.set(row.id, {
        id: row.id,
        nome: row.nome,
        qso: row.qso,
        forca_id: row.forca_id,
        tipo_permuta: row.tipo_permuta,
        forca_sigla: row.forca_sigla,
        forca_nome: row.forca_nome,
        posto_graduacao_nome: row.posto_graduacao_nome,
        ocultar_no_mapa: row.ocultar_no_mapa === 1,
        em_destaque: row.em_destaque === 1,
        lotacao_interestadual: row.lotacao_interestadual === 1,
        unidade_atual_id: row.resolved_unidade_atual_id,
        municipio_atual_id: row.municipio_atual_id_resolved,
        estado_atual_id: row.estado_atual_id_resolved,
        unidade_atual: row.unidade_atual,
        municipio_atual: row.municipio_atual,
        estado_atual: row.estado_atual,
        lat: row.lat != null ? parseFloat(row.lat) : null,
        lng: row.lng != null ? parseFloat(row.lng) : null,
        intencoes: [],
      });
    }

    const destinoLabel = buildDestinoLabel(row);
    byId.get(row.id).intencoes.push({
      id: row.intencao_id,
      prioridade: row.prioridade,
      tipo_intencao: row.tipo_intencao,
      estado_id: row.estado_id,
      municipio_id: row.municipio_id,
      unidade_id: row.unidade_id,
      raio_km: row.raio_km != null ? Number(row.raio_km) : null,
      destino_lat: row.destino_lat != null ? parseFloat(row.destino_lat) : null,
      destino_lng: row.destino_lng != null ? parseFloat(row.destino_lng) : null,
      destino_label: destinoLabel,
    });
  }

  return [...byId.values()];
}

function buildDestinoLabel(row) {
  if (row.tipo_intencao === 'UNIDADE') {
    const unidade = row.unidade_destino_nome || 'unidade';
    const mun = row.municipio_destino_nome || '';
    const uf = row.estado_destino_sigla || '';
    return mun ? `${unidade} (${mun}-${uf})` : unidade;
  }
  if (row.tipo_intencao === 'MUNICIPIO') {
    const mun = row.municipio_destino_nome || 'município';
    const uf = row.estado_destino_sigla || '';
    return uf ? `${mun}-${uf}` : mun;
  }
  if (row.tipo_intencao === 'ESTADO') {
    return row.estado_destino_sigla || 'estado';
  }
  return row.estado_destino_sigla || 'estado';
}

async function loadPolicialProfile(policialId) {
  const [rows] = await db.execute(
    `
    SELECT
      p.id,
      p.nome,
      p.forca_id,
      p.lotacao_interestadual,
      p.unidade_atual_id,
      p.municipio_atual_id,
      f.tipo_permuta,
      f.sigla AS forca_sigla,
      f.nome AS forca_nome
    FROM policiais p
    JOIN forcas_policiais f ON p.forca_id = f.id
    WHERE p.id = ?
    LIMIT 1
  `,
    [policialId]
  );

  if (rows.length === 0) return null;

  const row = rows[0];
  return {
    id: row.id,
    nome: row.nome,
    forca_id: row.forca_id,
    tipo_permuta: row.tipo_permuta,
    forca_sigla: row.forca_sigla,
    forca_nome: row.forca_nome,
    lotacao_interestadual: row.lotacao_interestadual === 1,
    unidade_atual_id: row.unidade_atual_id,
    municipio_atual_id: row.municipio_atual_id,
  };
}

async function findActivePolicialIds(limit = 0) {
  const sql = `
    SELECT DISTINCT p.id
    FROM policiais p
    JOIN intencoes i ON i.policial_id = p.id
    WHERE p.status_verificacao = 'VERIFICADO'
      AND i.tipo_intencao IN ('UNIDADE', 'MUNICIPIO', 'ESTADO')
      AND (
        COALESCE(i.unidade_atual_id, p.unidade_atual_id) IS NOT NULL
        OR COALESCE(i.municipio_atual_id, p.municipio_atual_id) IS NOT NULL
      )
    ORDER BY p.id ASC
    ${limit > 0 ? 'LIMIT ?' : ''}
  `;
  const [rows] = limit > 0 ? await db.execute(sql, [limit]) : await db.execute(sql);
  return rows.map((r) => r.id);
}

module.exports = {
  loadGraphNodes,
  loadPolicialProfile,
  findActivePolicialIds,
};
