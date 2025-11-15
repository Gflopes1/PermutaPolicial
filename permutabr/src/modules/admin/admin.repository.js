// /src/modules/admin/admin.repository.js

const db = require('../../config/db');
const ApiError = require('../../core/utils/ApiError');

class AdminRepository {
  async getEstatisticas() {
    const [policiais] = await db.query('SELECT COUNT(*) as count FROM policiais');
    const [unidades] = await db.query('SELECT COUNT(*) as count FROM unidades');
    const [intencoes] = await db.query('SELECT COUNT(*) as count FROM intencoes');
    const [verificacoes] = await db.query("SELECT COUNT(*) as count FROM policiais WHERE status_verificacao = 'PENDENTE'");

    return {
      total_policiais: policiais[0].count,
      total_unidades: unidades[0].count,
      total_intencoes: intencoes[0].count,
      verificacoes_pendentes: verificacoes[0].count,
    };
  }

  async findSugestoesPendentes() {
    const [sugestoes] = await db.query("SELECT * FROM sugestoes_unidades WHERE status = 'PENDENTE'");
    return sugestoes;
  }

  async aprovarSugestao(sugestaoId) {
    // Verifica se a sugestão existe e está pendente
    const [sugestoes] = await db.execute("SELECT * FROM sugestoes_unidades WHERE id = ? AND status = 'PENDENTE'", [sugestaoId]);
    if (sugestoes.length === 0) {
      throw new ApiError(404, 'Sugestão não encontrada ou já processada.');
    }
    const sugestao = sugestoes[0];

    // Cria a unidade
    await db.execute(
      'INSERT INTO unidades (nome, municipio_id, forca_id, generica) VALUES (?, ?, ?, FALSE)',
      [sugestao.nome_sugerido, sugestao.municipio_id, sugestao.forca_id]
    );
    
    // Atualiza o status da sugestão
    await db.execute("UPDATE sugestoes_unidades SET status = 'APROVADA' WHERE id = ?", [sugestaoId]);
  }

  async updateStatusSugestao(sugestaoId, status) {
    const [result] = await db.execute("UPDATE sugestoes_unidades SET status = ? WHERE id = ? AND status = 'PENDENTE'", [status, sugestaoId]);
    return result.affectedRows > 0;
  }

  async findVerificacoesPendentes() {
    const query = `
      SELECT p.id, p.nome, p.email, f.sigla as forca_sigla, p.criado_em 
      FROM policiais p
      JOIN forcas_policiais f ON p.forca_id = f.id
      WHERE p.status_verificacao = 'PENDENTE'
    `;
    const [verificacoes] = await db.query(query);
    return verificacoes;
  }

  async updateStatusPolicial(policialId, status) {
    const [result] = await db.execute("UPDATE policiais SET status_verificacao = ? WHERE id = ? AND status_verificacao = 'PENDENTE'", [status, policialId]);
    return result.affectedRows > 0;
  }

  async findAllPoliciais(filters = {}) {
    let query = `
      SELECT 
        p.id, p.nome, p.email, p.id_funcional, p.qso, p.status_verificacao,
        p.criado_em, p.embaixador,
        f.sigla as forca_sigla, f.nome as forca_nome,
        u.nome as unidade_atual,
        m.nome as municipio_atual,
        e.sigla as estado_atual
      FROM policiais p
      LEFT JOIN forcas_policiais f ON p.forca_id = f.id
      LEFT JOIN unidades u ON p.unidade_atual_id = u.id
      LEFT JOIN municipios m ON u.municipio_id = m.id
      LEFT JOIN estados e ON m.estado_id = e.id
      WHERE 1=1
    `;
    const params = [];

    if (filters.status_verificacao) {
      query += ' AND p.status_verificacao = ?';
      params.push(filters.status_verificacao);
    }
    if (filters.forca_id) {
      query += ' AND p.forca_id = ?';
      params.push(filters.forca_id);
    }
    if (filters.search) {
      query += ' AND (p.nome LIKE ? OR p.email LIKE ? OR p.id_funcional LIKE ?)';
      const searchTerm = `%${filters.search}%`;
      params.push(searchTerm, searchTerm, searchTerm);
    }

    const limit = parseInt(filters.limit, 10) || 50;
    const offset = parseInt(filters.offset, 10) || 0;

    query += ' ORDER BY p.criado_em DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);

    const [policiais] = await db.query(query, params);
    return policiais;
  }

  async countPoliciais(filters = {}) {
    let query = 'SELECT COUNT(*) as total FROM policiais WHERE 1=1';
    const params = [];

    if (filters.status_verificacao) {
      query += ' AND status_verificacao = ?';
      params.push(filters.status_verificacao);
    }
    if (filters.forca_id) {
      query += ' AND forca_id = ?';
      params.push(filters.forca_id);
    }
    if (filters.search) {
      query += ' AND (nome LIKE ? OR email LIKE ? OR id_funcional LIKE ?)';
      const searchTerm = `%${filters.search}%`;
      params.push(searchTerm, searchTerm, searchTerm);
    }

    const [result] = await db.query(query, params);
    return result[0].total;
  }

  async updatePolicial(policialId, updateData) {
    const allowedFields = ['status_verificacao', 'embaixador', 'forca_id', 'unidade_atual_id'];
    const fieldsToUpdate = {};
    
    for (const field of allowedFields) {
      if (updateData[field] !== undefined) {
        fieldsToUpdate[field] = updateData[field];
      }
    }

    if (Object.keys(fieldsToUpdate).length === 0) {
      return false;
    }

    const setClause = Object.keys(fieldsToUpdate).map(key => `${key} = ?`).join(', ');
    const values = [...Object.values(fieldsToUpdate), policialId];
    const query = `UPDATE policiais SET ${setClause} WHERE id = ?`;

    const [result] = await db.execute(query, values);
    return result.affectedRows > 0;
  }
}

module.exports = new AdminRepository();