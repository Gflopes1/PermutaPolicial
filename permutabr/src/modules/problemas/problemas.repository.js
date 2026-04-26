// /src/modules/problemas/problemas.repository.js

const db = require('../../config/db');

class ProblemasRepository {
  // Cria um relato de problema
  async criarRelato(relatoData) {
    const { usuario_id, pagina, detalhes, ip_address, user_agent } = relatoData;
    const query = `
      INSERT INTO problema_relatos (usuario_id, pagina, detalhes, ip_address, user_agent)
      VALUES (?, ?, ?, ?, ?)
    `;
    const [result] = await db.execute(query, [usuario_id, pagina, detalhes, ip_address, user_agent]);
    return result.insertId;
  }

  // Busca relatos com filtros
  async buscarRelatos(filtros = {}) {
    const { status, pagina, usuario_id, dataInicio, dataFim, page = 1, perPage = 20 } = filtros;
    let query = `
      SELECT 
        pr.*,
        p.nome as usuario_nome,
        p.email as usuario_email,
        admin.nome as resolvido_por_nome
      FROM problema_relatos pr
      LEFT JOIN policiais p ON pr.usuario_id = p.id
      LEFT JOIN policiais admin ON pr.resolvido_por = admin.id
      WHERE 1=1
    `;
    const params = [];

    if (status) {
      query += ' AND pr.status = ?';
      params.push(status);
    }

    if (pagina) {
      query += ' AND pr.pagina LIKE ?';
      params.push(`%${pagina}%`);
    }

    if (usuario_id) {
      query += ' AND pr.usuario_id = ?';
      params.push(usuario_id);
    }

    if (dataInicio) {
      query += ' AND pr.criado_em >= ?';
      params.push(dataInicio);
    }

    if (dataFim) {
      query += ' AND pr.criado_em <= ?';
      params.push(dataFim);
    }

    query += ' ORDER BY pr.criado_em DESC';

    // Paginação
    const offset = (page - 1) * perPage;
    query += ' LIMIT ? OFFSET ?';
    params.push(perPage, offset);

    const [relatos] = await db.execute(query, params);
    return relatos;
  }

  // Conta total de relatos com filtros
  async contarRelatos(filtros = {}) {
    const { status, pagina, usuario_id, dataInicio, dataFim } = filtros;
    let query = 'SELECT COUNT(*) as total FROM problema_relatos pr WHERE 1=1';
    const params = [];

    if (status) {
      query += ' AND pr.status = ?';
      params.push(status);
    }

    if (pagina) {
      query += ' AND pr.pagina LIKE ?';
      params.push(`%${pagina}%`);
    }

    if (usuario_id) {
      query += ' AND pr.usuario_id = ?';
      params.push(usuario_id);
    }

    if (dataInicio) {
      query += ' AND pr.criado_em >= ?';
      params.push(dataInicio);
    }

    if (dataFim) {
      query += ' AND pr.criado_em <= ?';
      params.push(dataFim);
    }

    const [result] = await db.execute(query, params);
    return result[0].total;
  }

  // Busca relato por ID
  async buscarRelatoPorId(id) {
    const query = `
      SELECT 
        pr.*,
        p.nome as usuario_nome,
        p.email as usuario_email,
        admin.nome as resolvido_por_nome
      FROM problema_relatos pr
      LEFT JOIN policiais p ON pr.usuario_id = p.id
      LEFT JOIN policiais admin ON pr.resolvido_por = admin.id
      WHERE pr.id = ?
    `;
    const [relatos] = await db.execute(query, [id]);
    return relatos[0] || null;
  }

  // Atualiza status do relato
  async atualizarStatus(id, status, resolvidoPor = null, resolucao = null) {
    const query = `
      UPDATE problema_relatos
      SET status = ?,
          resolvido_por = ?,
          resolucao = ?,
          resolvido_em = CASE WHEN ? = 'RESOLVIDO' THEN NOW() ELSE resolvido_em END
      WHERE id = ?
    `;
    await db.execute(query, [status, resolvidoPor, resolucao, status, id]);
  }

  // Estatísticas de relatos
  async getEstatisticas(dataInicio = null, dataFim = null) {
    let query = `
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'PENDENTE' THEN 1 ELSE 0 END) as pendentes,
        SUM(CASE WHEN status = 'EM_ANALISE' THEN 1 ELSE 0 END) as em_analise,
        SUM(CASE WHEN status = 'RESOLVIDO' THEN 1 ELSE 0 END) as resolvidos,
        SUM(CASE WHEN status = 'DESCARTADO' THEN 1 ELSE 0 END) as descartados
      FROM problema_relatos
      WHERE 1=1
    `;
    const params = [];

    if (dataInicio) {
      query += ' AND criado_em >= ?';
      params.push(dataInicio);
    }

    if (dataFim) {
      query += ' AND criado_em <= ?';
      params.push(dataFim);
    }

    const [result] = await db.execute(query, params);
    return result[0];
  }

  // Relatos por página
  async getRelatosPorPagina(dataInicio = null, dataFim = null) {
    let query = `
      SELECT 
        pagina,
        COUNT(*) as total,
        SUM(CASE WHEN status = 'PENDENTE' THEN 1 ELSE 0 END) as pendentes
      FROM problema_relatos
      WHERE 1=1
    `;
    const params = [];

    if (dataInicio) {
      query += ' AND criado_em >= ?';
      params.push(dataInicio);
    }

    if (dataFim) {
      query += ' AND criado_em <= ?';
      params.push(dataFim);
    }

    query += ' GROUP BY pagina ORDER BY total DESC';

    const [result] = await db.execute(query, params);
    return result;
  }
}

module.exports = new ProblemasRepository();
