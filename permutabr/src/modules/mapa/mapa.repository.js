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
        SELECT m.id, m.nome, m.latitude, m.longitude, COUNT(DISTINCT i.policial_id) as contagem
        FROM municipios m
        JOIN intencoes i ON (i.municipio_atual_id = m.id OR 
            EXISTS (SELECT 1 FROM unidades u WHERE u.id = i.unidade_atual_id AND u.municipio_id = m.id))
        JOIN policiais p ON i.policial_id = p.id
        WHERE m.latitude IS NOT NULL AND m.longitude IS NOT NULL 
        AND p.agente_verificado = 1
        AND (i.unidade_atual_id IS NOT NULL OR i.municipio_atual_id IS NOT NULL)
        ${whereClause}
        GROUP BY m.id, m.nome, m.latitude, m.longitude;
    `;
    // ✅ SEGURANÇA: Usar db.execute para queries com parâmetros
    const [origens] = await db.execute(query, params);
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
    // ✅ SEGURANÇA: Usar db.execute para queries com parâmetros
    const [destinos] = await db.execute(query, params);
    return destinos;
  }

  async findSaindoDetails(filters) {
    const { id, forca_id } = filters;
    const params = [id];
    // Usa subquery para garantir que cada policial apareça apenas uma vez
    // Seleciona a primeira intenção (menor prioridade) para obter o local
    let query = `
        SELECT DISTINCT
          p.id as policial_id,
          CASE WHEN p.ocultar_no_mapa = 0 THEN p.nome ELSE 'Usuário não identificado' END as policial_nome, 
          CASE WHEN p.ocultar_no_mapa = 0 THEN p.qso ELSE NULL END as qso,
          p.ocultar_no_mapa,
          f.sigla as forca_sigla, 
          u_atual.nome as unidade_nome,
          COALESCE(m_direto.nome, m_unidade.nome) as municipio_atual,
          COALESCE(e_direto.sigla, e_unidade.sigla) as estado_atual,
          (
            SELECT GROUP_CONCAT(
              DISTINCT CASE 
                WHEN i2.tipo_intencao = 'UNIDADE' THEN CONCAT('Unidade: ', u2.nome)
                WHEN i2.tipo_intencao = 'MUNICIPIO' THEN CONCAT('Município: ', m2.nome, '-', e2.sigla)
                WHEN i2.tipo_intencao = 'ESTADO' THEN CONCAT('Estado: ', e2.sigla)
              END
              ORDER BY i2.prioridade
              SEPARATOR ' | '
            )
            FROM intencoes i2
            LEFT JOIN unidades u2 ON i2.unidade_id = u2.id
            LEFT JOIN municipios m2 ON i2.municipio_id = m2.id OR u2.municipio_id = m2.id
            LEFT JOIN estados e2 ON i2.estado_id = e2.id OR m2.estado_id = e2.id
            WHERE i2.policial_id = p.id
          ) as destinos_desejados
        FROM (
          SELECT DISTINCT i.policial_id, 
            MIN(i.prioridade) as min_prioridade
          FROM intencoes i
          WHERE (i.municipio_atual_id = ? OR 
            EXISTS (SELECT 1 FROM unidades u WHERE u.id = i.unidade_atual_id AND u.municipio_id = ?))
          AND (i.unidade_atual_id IS NOT NULL OR i.municipio_atual_id IS NOT NULL)
          GROUP BY i.policial_id
        ) as policiais_municipio
        JOIN intencoes i ON i.policial_id = policiais_municipio.policial_id 
          AND i.prioridade = policiais_municipio.min_prioridade
        JOIN policiais p ON i.policial_id = p.id
        JOIN forcas_policiais f ON p.forca_id = f.id
        LEFT JOIN unidades u_atual ON i.unidade_atual_id = u_atual.id
        LEFT JOIN municipios m_direto ON i.municipio_atual_id = m_direto.id
        LEFT JOIN estados e_direto ON m_direto.estado_id = e_direto.id
        LEFT JOIN municipios m_unidade ON u_atual.municipio_id = m_unidade.id
        LEFT JOIN estados e_unidade ON m_unidade.estado_id = e_unidade.id
        WHERE p.status_verificacao = 'VERIFICADO'
    `;
    params.push(id); // Adiciona o id novamente para a segunda condição
    if (forca_id) {
      query += ' AND p.forca_id = ?';
      params.push(forca_id);
    }
    // ✅ SEGURANÇA: Usar db.execute para queries com parâmetros
    const [details] = await db.execute(query, params);
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
          u_atual.nome as unidade_nome,
          COALESCE(m_atual_direto.nome, m_atual_unidade.nome) as municipio_atual,
          COALESCE(e_atual_direto.sigla, e_atual_unidade.sigla) as estado_atual,
          m_dest.nome as municipio_desejado,
          e_dest.sigla as estado_desejado
        FROM intencoes i
        JOIN policiais p ON i.policial_id = p.id
        JOIN forcas_policiais f ON p.forca_id = f.id
        LEFT JOIN unidades u_atual ON i.unidade_atual_id = u_atual.id
        LEFT JOIN municipios m_atual_direto ON i.municipio_atual_id = m_atual_direto.id
        LEFT JOIN estados e_atual_direto ON m_atual_direto.estado_id = e_atual_direto.id
        LEFT JOIN municipios m_atual_unidade ON u_atual.municipio_id = m_atual_unidade.id
        LEFT JOIN estados e_atual_unidade ON m_atual_unidade.estado_id = e_atual_unidade.id
        JOIN municipios m_dest ON i.municipio_id = m_dest.id
        JOIN estados e_dest ON m_dest.estado_id = e_dest.id
        WHERE i.tipo_intencao = 'MUNICIPIO' AND i.municipio_id = ? 
          AND p.agente_verificado = 1
          AND (i.unidade_atual_id IS NOT NULL OR i.municipio_atual_id IS NOT NULL)
    `;
    if (forca_id) {
      query += ' AND p.forca_id = ?';
      params.push(forca_id);
    }
    // ✅ SEGURANÇA: Usar db.execute para queries com parâmetros
    const [details] = await db.execute(query, params);
    return details;
  }
}

module.exports = new MapaRepository();