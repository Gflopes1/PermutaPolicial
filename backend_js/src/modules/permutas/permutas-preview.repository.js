const db = require('../../config/db');

const VERIFICADO_POLICIAL = "status_verificacao = 'VERIFICADO'";
const VERIFICADO_P = "p.status_verificacao = 'VERIFICADO'";

class PermutasPreviewRepository {
  async findMunicipioByNome(nome, estadoSigla = null) {
    const termo = String(nome || '').trim();
    if (!termo) return null;

    let query = `
      SELECT m.id, m.nome, m.latitude, m.longitude, m.estado_id, e.sigla AS estado_sigla
      FROM municipios m
      JOIN estados e ON e.id = m.estado_id
      WHERE m.nome LIKE ?
    `;
    const params = [`%${termo}%`];

    if (estadoSigla) {
      query += ' AND e.sigla = ?';
      params.push(String(estadoSigla).trim().toUpperCase());
    }

    query += `
      ORDER BY
        CASE WHEN LOWER(m.nome) = LOWER(?) THEN 0
             WHEN LOWER(m.nome) LIKE LOWER(?) THEN 1
             ELSE 2 END,
        m.nome ASC
      LIMIT 1
    `;
    params.push(termo, `${termo}%`);

    const [rows] = await db.execute(query, params);
    return rows[0] || null;
  }

  async findMunicipioById(id) {
    const [rows] = await db.execute(
      `SELECT m.id, m.nome, m.latitude, m.longitude, m.estado_id, e.sigla AS estado_sigla
       FROM municipios m
       JOIN estados e ON e.id = m.estado_id
       WHERE m.id = ? LIMIT 1`,
      [id]
    );
    return rows[0] || null;
  }

  async findForcaByTipoPermuta(tipoPermuta) {
    const [rows] = await db.execute(
      `SELECT id, sigla, nome, tipo_permuta
       FROM forcas_policiais
       WHERE tipo_permuta = ?
       ORDER BY id ASC
       LIMIT 1`,
      [String(tipoPermuta).trim().toUpperCase()]
    );
    return rows[0] || null;
  }

  /** Resolve corporação estadual pela UF (ex.: PM + SP → PMSP). */
  async findForcaByTipoAndEstado(tipoPermuta, estadoSigla) {
    const tipo = String(tipoPermuta).trim().toUpperCase();
    const uf = String(estadoSigla).trim().toUpperCase();
    const [rows] = await db.execute(
      `SELECT id, sigla, nome, tipo_permuta
       FROM forcas_policiais
       WHERE tipo_permuta = ?`,
      [tipo]
    );

    const scored = rows
      .map((row) => {
        const sigla = String(row.sigla).toUpperCase();
        let score = 100;
        if (sigla.endsWith(uf)) score = sigla.length;
        else if (sigla.includes(`-${uf}`)) score = sigla.length + 1;
        else if (sigla.includes(uf)) score = sigla.length + 5;
        return { row, score };
      })
      .filter(({ score }) => score < 100)
      .sort((a, b) => a.score - b.score);

    return scored[0]?.row || null;
  }

  async findForcaById(id) {
    const [rows] = await db.execute(
      `SELECT id, sigla, nome, tipo_permuta FROM forcas_policiais WHERE id = ? LIMIT 1`,
      [id]
    );
    return rows[0] || null;
  }

  async getPublicStats() {
    const [[usuariosRow]] = await db.execute(
      `SELECT COUNT(*) AS total FROM policiais WHERE ${VERIFICADO_POLICIAL}`
    );

    const [[unidadesRow]] = await db.execute(`
      SELECT COUNT(DISTINCT resolved.unidade_id) AS total
      FROM (
        SELECT DISTINCT
          i.policial_id,
          COALESCE(i.unidade_atual_id, p.unidade_atual_id) AS unidade_id
        FROM intencoes i
        JOIN policiais p ON p.id = i.policial_id
        WHERE ${VERIFICADO_P}
          AND COALESCE(i.unidade_atual_id, p.unidade_atual_id) IS NOT NULL
          AND (i.unidade_atual_id IS NOT NULL OR i.municipio_atual_id IS NOT NULL)
      ) AS resolved
      WHERE resolved.unidade_id IS NOT NULL
    `);

    return {
      usuarios_verificados: Number(usuariosRow?.total || 0),
      unidades_ativas: Number(unidadesRow?.total || 0),
    };
  }
}

module.exports = new PermutasPreviewRepository();
