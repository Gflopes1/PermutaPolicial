const db = require('../../config/db');

class ConsultoriaJuridicaRepository {
  async findAll({ onlyActive = false } = {}) {
    let query = 'SELECT * FROM consultoria_advogados';
    if (onlyActive) query += ' WHERE ativo = 1';
    query += ' ORDER BY ordem ASC, id DESC';
    const [rows] = await db.execute(query);
    return rows;
  }

  async findById(id, { onlyActive = false } = {}) {
    let query = 'SELECT * FROM consultoria_advogados WHERE id = ?';
    const params = [id];
    if (onlyActive) query += ' AND ativo = 1';
    const [rows] = await db.execute(query, params);
    return rows[0] || null;
  }

  async create(data) {
    const {
      nome,
      descricao_curta,
      descricao_detalhada,
      foto_url,
      site_url,
      contato_whatsapp,
      contato_telefone,
      contato_email,
      ordem,
      ativo,
    } = data;

    const [result] = await db.execute(
      `INSERT INTO consultoria_advogados
        (nome, descricao_curta, descricao_detalhada, foto_url, site_url,
         contato_whatsapp, contato_telefone, contato_email, ordem, ativo)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        nome,
        descricao_curta,
        descricao_detalhada || null,
        foto_url,
        site_url || null,
        contato_whatsapp || null,
        contato_telefone || null,
        contato_email || null,
        ordem ?? 0,
        ativo !== false ? 1 : 0,
      ]
    );
    return result.insertId;
  }

  async update(id, data) {
    const {
      nome,
      descricao_curta,
      descricao_detalhada,
      foto_url,
      site_url,
      contato_whatsapp,
      contato_telefone,
      contato_email,
      ordem,
      ativo,
    } = data;

    const [result] = await db.execute(
      `UPDATE consultoria_advogados SET
        nome = ?, descricao_curta = ?, descricao_detalhada = ?, foto_url = ?,
        site_url = ?, contato_whatsapp = ?, contato_telefone = ?, contato_email = ?,
        ordem = ?, ativo = ?
       WHERE id = ?`,
      [
        nome,
        descricao_curta,
        descricao_detalhada || null,
        foto_url,
        site_url || null,
        contato_whatsapp || null,
        contato_telefone || null,
        contato_email || null,
        ordem ?? 0,
        ativo !== false ? 1 : 0,
        id,
      ]
    );
    return result.affectedRows > 0;
  }

  async delete(id) {
    const [result] = await db.execute('DELETE FROM consultoria_advogados WHERE id = ?', [id]);
    return result.affectedRows > 0;
  }

  async registerClick(advogadoId, usuarioId, tipoClique) {
    await db.execute(
      'INSERT INTO consultoria_cliques (advogado_id, usuario_id, tipo_clique) VALUES (?, ?, ?)',
      [advogadoId, usuarioId || null, tipoClique]
    );
  }

  async getClickStats() {
    const [totals] = await db.execute(
      `SELECT
         a.id,
         a.nome,
         SUM(c.tipo_clique = 'contato') AS cliques_contato,
         SUM(c.tipo_clique = 'site') AS cliques_site,
         COUNT(c.id) AS cliques_total
       FROM consultoria_advogados a
       LEFT JOIN consultoria_cliques c ON c.advogado_id = a.id
       GROUP BY a.id, a.nome
       ORDER BY a.ordem ASC, a.id DESC`
    );

    const [byUser] = await db.execute(
      `SELECT
         c.advogado_id,
         a.nome AS advogado_nome,
         c.tipo_clique,
         c.usuario_id,
         p.nome AS usuario_nome,
         p.email AS usuario_email,
         COUNT(*) AS total,
         MAX(c.created_at) AS ultimo_clique
       FROM consultoria_cliques c
       JOIN consultoria_advogados a ON a.id = c.advogado_id
       LEFT JOIN policiais p ON p.id = c.usuario_id
       GROUP BY c.advogado_id, a.nome, c.tipo_clique, c.usuario_id, p.nome, p.email
       ORDER BY ultimo_clique DESC`
    );

    return { totals, by_user: byUser };
  }
}

module.exports = new ConsultoriaJuridicaRepository();
