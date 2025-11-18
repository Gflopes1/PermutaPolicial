// /src/modules/forum/forum.repository.js

const db = require('../../config/db');

class ForumRepository {
  // Categorias
  async findAllCategorias() {
    const [rows] = await db.execute(
      'SELECT * FROM forum_categorias WHERE ativo = TRUE ORDER BY ordem ASC, nome ASC'
    );
    return rows;
  }

  async findCategoriaById(id) {
    const [rows] = await db.execute(
      'SELECT * FROM forum_categorias WHERE id = ?',
      [id]
    );
    return rows[0] || null;
  }

  // Tópicos
  async findTopicosByCategoria(categoriaId, limit = 20, offset = 0) {
    const query = `
      SELECT 
        t.id,
        t.categoria_id,
        t.autor_id,
        t.titulo,
        t.conteudo,
        t.fixado,
        t.bloqueado,
        t.visualizacoes,
        t.criado_em,
        t.atualizado_em,
        p.nome as autor_nome,
        p.email as autor_email,
        c.nome as categoria_nome,
        (
          SELECT COUNT(*) 
          FROM forum_respostas r 
          WHERE r.topico_id = t.id AND r.status_moderacao = 'APROVADO'
        ) as total_respostas,
        (
          SELECT r.criado_em 
          FROM forum_respostas r 
          WHERE r.topico_id = t.id AND r.status_moderacao = 'APROVADO'
          ORDER BY r.criado_em DESC 
          LIMIT 1
        ) as ultima_resposta_data
      FROM forum_topicos t
      LEFT JOIN policiais p ON t.autor_id = p.id
      LEFT JOIN forum_categorias c ON t.categoria_id = c.id
      WHERE t.categoria_id = ?
      ORDER BY t.fixado DESC, t.atualizado_em DESC
      LIMIT ? OFFSET ?
    `;
    const [rows] = await db.execute(query, [categoriaId, limit, offset]);
    return rows;
  }

  async findTopicoById(id) {
    const query = `
      SELECT 
        t.*,
        p.nome as autor_nome,
        p.email as autor_email,
        c.nome as categoria_nome,
        c.cor as categoria_cor
      FROM forum_topicos t
      LEFT JOIN policiais p ON t.autor_id = p.id
      LEFT JOIN forum_categorias c ON t.categoria_id = c.id
      WHERE t.id = ?
    `;
    const [rows] = await db.execute(query, [id]);
    return rows[0] || null;
  }

  async createTopico(topicoData) {
    const { categoria_id, autor_id, titulo, conteudo } = topicoData;
    const [result] = await db.execute(
      'INSERT INTO forum_topicos (categoria_id, autor_id, titulo, conteudo) VALUES (?, ?, ?, ?)',
      [categoria_id, autor_id, titulo, conteudo]
    );

    return await this.findTopicoById(result.insertId);
  }

  async updateTopico(id, updateData) {
    const fields = Object.keys(updateData);
    if (fields.length === 0) return null;

    const setClause = fields.map(field => `${field} = ?`).join(', ');
    const values = [...Object.values(updateData), id];

    await db.execute(
      `UPDATE forum_topicos SET ${setClause} WHERE id = ?`,
      values
    );

    return await this.findTopicoById(id);
  }

  async deleteTopico(id) {
    const [result] = await db.execute(
      'DELETE FROM forum_topicos WHERE id = ?',
      [id]
    );
    return result.affectedRows > 0;
  }

  async incrementarVisualizacoes(id) {
    await db.execute(
      'UPDATE forum_topicos SET visualizacoes = visualizacoes + 1 WHERE id = ?',
      [id]
    );
  }

  async searchTopicos(searchTerm, limit = 20, offset = 0) {
    const query = `
      SELECT 
        t.id,
        t.categoria_id,
        t.autor_id,
        t.titulo,
        t.conteudo,
        t.fixado,
        t.bloqueado,
        t.visualizacoes,
        t.criado_em,
        t.atualizado_em,
        p.nome as autor_nome,
        c.nome as categoria_nome,
        (
          SELECT COUNT(*) 
          FROM forum_respostas r 
          WHERE r.topico_id = t.id AND r.status_moderacao = 'APROVADO'
        ) as total_respostas
      FROM forum_topicos t
      LEFT JOIN policiais p ON t.autor_id = p.id
      LEFT JOIN forum_categorias c ON t.categoria_id = c.id
      WHERE MATCH(t.titulo, t.conteudo) AGAINST(? IN NATURAL LANGUAGE MODE)
      ORDER BY t.fixado DESC, t.atualizado_em DESC
      LIMIT ? OFFSET ?
    `;
    const [rows] = await db.execute(query, [searchTerm, limit, offset]);
    return rows;
  }

  // Respostas
  async findRespostasByTopico(topicoId, limit = 50, offset = 0) {
    const query = `
      SELECT 
        r.id,
        r.topico_id,
        r.autor_id,
        r.conteudo,
        r.resposta_id,
        r.criado_em,
        r.atualizado_em,
        p.nome as autor_nome,
        p.email as autor_email,
        (
          SELECT COUNT(*) 
          FROM forum_reacoes re 
          WHERE re.resposta_id = r.id AND re.tipo = 'curtida'
        ) as curtidas
      FROM forum_respostas r
      LEFT JOIN policiais p ON r.autor_id = p.id
      WHERE r.topico_id = ? AND r.resposta_id IS NULL
      ORDER BY r.criado_em ASC
      LIMIT ? OFFSET ?
    `;
    const [rows] = await db.execute(query, [topicoId, limit, offset]);
    
    // Busca comentários (respostas a respostas)
    for (let resposta of rows) {
      const [comentarios] = await db.execute(
        `SELECT 
          r.id,
          r.topico_id,
          r.autor_id,
          r.conteudo,
          r.resposta_id,
          r.criado_em,
          r.atualizado_em,
          p.nome as autor_nome,
          p.email as autor_email
        FROM forum_respostas r
        LEFT JOIN policiais p ON r.autor_id = p.id
        WHERE r.resposta_id = ?
        ORDER BY r.criado_em ASC`,
        [resposta.id]
      );
      resposta.comentarios = comentarios;
    }

    return rows;
  }

  async createResposta(respostaData) {
    const { topico_id, autor_id, conteudo, resposta_id } = respostaData;
    const [result] = await db.execute(
      'INSERT INTO forum_respostas (topico_id, autor_id, conteudo, resposta_id) VALUES (?, ?, ?, ?)',
      [topico_id, autor_id, conteudo, resposta_id || null]
    );

    // Atualiza o timestamp do tópico
    await db.execute(
      'UPDATE forum_topicos SET atualizado_em = CURRENT_TIMESTAMP WHERE id = ?',
      [topico_id]
    );

    const query = `
      SELECT 
        r.*,
        p.nome as autor_nome,
        p.email as autor_email
      FROM forum_respostas r
      LEFT JOIN policiais p ON r.autor_id = p.id
      WHERE r.id = ?
    `;
    const [rows] = await db.execute(query, [result.insertId]);
    return rows[0];
  }

  async updateResposta(id, conteudo) {
    await db.execute(
      'UPDATE forum_respostas SET conteudo = ?, atualizado_em = CURRENT_TIMESTAMP WHERE id = ?',
      [conteudo, id]
    );

    const query = `
      SELECT 
        r.*,
        p.nome as autor_nome,
        p.email as autor_email
      FROM forum_respostas r
      LEFT JOIN policiais p ON r.autor_id = p.id
      WHERE r.id = ?
    `;
    const [rows] = await db.execute(query, [id]);
    return rows[0];
  }

  async deleteResposta(id) {
    const [result] = await db.execute(
      'DELETE FROM forum_respostas WHERE id = ?',
      [id]
    );
    return result.affectedRows > 0;
  }

  // Reações
  async toggleReacao(tipo, topicoId, respostaId, usuarioId) {
    const table = topicoId ? 'topico_id' : 'resposta_id';
    const id = topicoId || respostaId;

    // Verifica se já existe
    const query = topicoId
      ? 'SELECT * FROM forum_reacoes WHERE topico_id = ? AND usuario_id = ? AND tipo = ?'
      : 'SELECT * FROM forum_reacoes WHERE resposta_id = ? AND usuario_id = ? AND tipo = ?';
    
    const [existing] = await db.execute(query, [id, usuarioId, tipo]);

    if (existing.length > 0) {
      // Remove reação
      const deleteQuery = topicoId
        ? 'DELETE FROM forum_reacoes WHERE topico_id = ? AND usuario_id = ? AND tipo = ?'
        : 'DELETE FROM forum_reacoes WHERE resposta_id = ? AND usuario_id = ? AND tipo = ?';
      await db.execute(deleteQuery, [id, usuarioId, tipo]);
      return { action: 'removed' };
    } else {
      // Adiciona reação
      const insertQuery = topicoId
        ? 'INSERT INTO forum_reacoes (topico_id, usuario_id, tipo) VALUES (?, ?, ?)'
        : 'INSERT INTO forum_reacoes (resposta_id, usuario_id, tipo) VALUES (?, ?, ?)';
      await db.execute(insertQuery, [id, usuarioId, tipo]);
      return { action: 'added' };
    }
  }

  async getReacoesByTopico(topicoId) {
    const [rows] = await db.execute(
      'SELECT tipo, COUNT(*) as total FROM forum_reacoes WHERE topico_id = ? GROUP BY tipo',
      [topicoId]
    );
    return rows;
  }

  async getReacoesByResposta(respostaId) {
    const [rows] = await db.execute(
      'SELECT tipo, COUNT(*) as total FROM forum_reacoes WHERE resposta_id = ? GROUP BY tipo',
      [respostaId]
    );
    return rows;
  }

  async verificarReacaoUsuario(tipo, topicoId, respostaId, usuarioId) {
    const query = topicoId
      ? 'SELECT * FROM forum_reacoes WHERE topico_id = ? AND usuario_id = ? AND tipo = ?'
      : 'SELECT * FROM forum_reacoes WHERE resposta_id = ? AND usuario_id = ? AND tipo = ?';
    const id = topicoId || respostaId;
    const [rows] = await db.execute(query, [id, usuarioId, tipo]);
    return rows.length > 0;
  }

  // Moderação - Tópicos
  async aprovarTopico(topicoId, moderadorId) {
    await db.execute(
      'UPDATE forum_topicos SET status_moderacao = "APROVADO", moderado_por = ?, moderado_em = CURRENT_TIMESTAMP, motivo_rejeicao = NULL WHERE id = ?',
      [moderadorId, topicoId]
    );
    return await this.findTopicoById(topicoId);
  }

  async rejeitarTopico(topicoId, moderadorId, motivoRejeicao) {
    await db.execute(
      'UPDATE forum_topicos SET status_moderacao = "REJEITADO", moderado_por = ?, moderado_em = CURRENT_TIMESTAMP, motivo_rejeicao = ? WHERE id = ?',
      [moderadorId, motivoRejeicao, topicoId]
    );
    return await this.findTopicoById(topicoId);
  }

  async toggleFixarTopico(topicoId) {
    const topico = await this.findTopicoById(topicoId);
    if (!topico) return null;
    
    const novoValor = topico.fixado ? 0 : 1;
    await db.execute(
      'UPDATE forum_topicos SET fixado = ? WHERE id = ?',
      [novoValor, topicoId]
    );
    return await this.findTopicoById(topicoId);
  }

  async toggleBloquearTopico(topicoId) {
    const topico = await this.findTopicoById(topicoId);
    if (!topico) return null;
    
    const novoValor = topico.bloqueado ? 0 : 1;
    await db.execute(
      'UPDATE forum_topicos SET bloqueado = ? WHERE id = ?',
      [novoValor, topicoId]
    );
    return await this.findTopicoById(topicoId);
  }

  // Moderação - Respostas
  async findRespostaById(id) {
    const query = `
      SELECT 
        r.*,
        p.nome as autor_nome,
        p.email as autor_email
      FROM forum_respostas r
      LEFT JOIN policiais p ON r.autor_id = p.id
      WHERE r.id = ?
    `;
    const [rows] = await db.execute(query, [id]);
    return rows[0] || null;
  }

  async aprovarResposta(respostaId, moderadorId) {
    await db.execute(
      'UPDATE forum_respostas SET status_moderacao = "APROVADO", moderado_por = ?, moderado_em = CURRENT_TIMESTAMP, motivo_rejeicao = NULL WHERE id = ?',
      [moderadorId, respostaId]
    );
    return await this.findRespostaById(respostaId);
  }

  async rejeitarResposta(respostaId, moderadorId, motivoRejeicao) {
    await db.execute(
      'UPDATE forum_respostas SET status_moderacao = "REJEITADO", moderado_por = ?, moderado_em = CURRENT_TIMESTAMP, motivo_rejeicao = ? WHERE id = ?',
      [moderadorId, motivoRejeicao, respostaId]
    );
    return await this.findRespostaById(respostaId);
  }

  // Listar tópicos pendentes de moderação
  async findTopicosPendentes(limit = 50, offset = 0) {
    const query = `
      SELECT 
        t.id,
        t.categoria_id,
        t.autor_id,
        t.titulo,
        t.conteudo,
        t.status_moderacao,
        t.motivo_rejeicao,
        t.moderado_por,
        t.moderado_em,
        t.fixado,
        t.bloqueado,
        t.visualizacoes,
        t.criado_em,
        t.atualizado_em,
        p.nome as autor_nome,
        p.email as autor_email,
        c.nome as categoria_nome,
        (
          SELECT COUNT(*) 
          FROM forum_respostas r 
          WHERE r.topico_id = t.id
        ) as total_respostas
      FROM forum_topicos t
      LEFT JOIN policiais p ON t.autor_id = p.id
      LEFT JOIN forum_categorias c ON t.categoria_id = c.id
      WHERE t.status_moderacao = 'PENDENTE'
      ORDER BY t.criado_em ASC
      LIMIT ? OFFSET ?
    `;
    const [rows] = await db.execute(query, [limit, offset]);
    return rows;
  }

  // Listar respostas pendentes de moderação
  async findRespostasPendentes(limit = 50, offset = 0) {
    const query = `
      SELECT 
        r.id,
        r.topico_id,
        r.autor_id,
        r.conteudo,
        r.status_moderacao,
        r.motivo_rejeicao,
        r.moderado_por,
        r.moderado_em,
        r.resposta_id,
        r.criado_em,
        r.atualizado_em,
        p.nome as autor_nome,
        p.email as autor_email,
        t.titulo as topico_titulo
      FROM forum_respostas r
      LEFT JOIN policiais p ON r.autor_id = p.id
      LEFT JOIN forum_topicos t ON r.topico_id = t.id
      WHERE r.status_moderacao = 'PENDENTE'
      ORDER BY r.criado_em ASC
      LIMIT ? OFFSET ?
    `;
    const [rows] = await db.execute(query, [limit, offset]);
    return rows;
  }
}

module.exports = new ForumRepository();

