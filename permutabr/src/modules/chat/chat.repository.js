// /src/modules/chat/chat.repository.js

const db = require('../../config/db');

class ChatRepository {
  // Busca ou cria uma conversa entre dois usuários
  async findOrCreateConversa(usuario1Id, usuario2Id) {
    // Garante que usuario1_id sempre seja menor que usuario2_id para evitar duplicatas
    const [id1, id2] = usuario1Id < usuario2Id ? [usuario1Id, usuario2Id] : [usuario2Id, usuario1Id];
    
    // Tenta encontrar conversa existente
    const [existing] = await db.execute(
      'SELECT * FROM conversas WHERE usuario1_id = ? AND usuario2_id = ?',
      [id1, id2]
    );

    if (existing.length > 0) {
      return existing[0];
    }

    // Cria nova conversa
    const [result] = await db.execute(
      'INSERT INTO conversas (usuario1_id, usuario2_id) VALUES (?, ?)',
      [id1, id2]
    );

    const [newConversa] = await db.execute(
      'SELECT * FROM conversas WHERE id = ?',
      [result.insertId]
    );

    return newConversa[0];
  }

  // Busca todas as conversas de um usuário
  async findConversasByUsuario(usuarioId) {
    const query = `
      SELECT 
        c.id,
        c.usuario1_id,
        c.usuario2_id,
        c.criado_em,
        c.atualizado_em,
        CASE 
          WHEN c.usuario1_id = ? THEN c.usuario2_id
          ELSE c.usuario1_id
        END as outro_usuario_id,
        p.nome as outro_usuario_nome,
        p.email as outro_usuario_email,
        (
          SELECT COUNT(*) 
          FROM mensagens m 
          WHERE m.conversa_id = c.id 
          AND m.remetente_id != ?
          AND m.lida = FALSE
        ) as mensagens_nao_lidas,
        (
          SELECT m.mensagem 
          FROM mensagens m 
          WHERE m.conversa_id = c.id 
          ORDER BY m.criado_em DESC 
          LIMIT 1
        ) as ultima_mensagem,
        (
          SELECT m.criado_em 
          FROM mensagens m 
          WHERE m.conversa_id = c.id 
          ORDER BY m.criado_em DESC 
          LIMIT 1
        ) as ultima_mensagem_data
      FROM conversas c
      LEFT JOIN policiais p ON (
        CASE 
          WHEN c.usuario1_id = ? THEN p.id = c.usuario2_id
          ELSE p.id = c.usuario1_id
        END
      )
      WHERE c.usuario1_id = ? OR c.usuario2_id = ?
      ORDER BY c.atualizado_em DESC
    `;
    
    const [rows] = await db.execute(query, [usuarioId, usuarioId, usuarioId, usuarioId, usuarioId]);
    return rows;
  }

  // Busca mensagens de uma conversa
  async findMensagensByConversa(conversaId, limit = 50, offset = 0) {
    const query = `
      SELECT 
        m.id,
        m.conversa_id,
        m.remetente_id,
        m.mensagem,
        m.lida,
        m.criado_em,
        p.nome as remetente_nome,
        p.email as remetente_email
      FROM mensagens m
      LEFT JOIN policiais p ON m.remetente_id = p.id
      WHERE m.conversa_id = ?
      ORDER BY m.criado_em DESC
      LIMIT ? OFFSET ?
    `;
    
    const [rows] = await db.execute(query, [conversaId, limit, offset]);
    return rows.reverse(); // Inverte para mostrar do mais antigo ao mais recente
  }

  // Cria uma nova mensagem
  async createMensagem(conversaId, remetenteId, mensagem) {
    const [result] = await db.execute(
      'INSERT INTO mensagens (conversa_id, remetente_id, mensagem) VALUES (?, ?, ?)',
      [conversaId, remetenteId, mensagem]
    );

    // Atualiza o timestamp da conversa
    await db.execute(
      'UPDATE conversas SET atualizado_em = CURRENT_TIMESTAMP WHERE id = ?',
      [conversaId]
    );

    // Busca a mensagem criada com informações do remetente
    const [mensagemCriada] = await db.execute(
      `SELECT 
        m.id,
        m.conversa_id,
        m.remetente_id,
        m.mensagem,
        m.lida,
        m.criado_em,
        p.nome as remetente_nome,
        p.email as remetente_email
      FROM mensagens m
      LEFT JOIN policiais p ON m.remetente_id = p.id
      WHERE m.id = ?`,
      [result.insertId]
    );

    return mensagemCriada[0];
  }

  // Marca mensagens como lidas
  async marcarMensagensComoLidas(conversaId, usuarioId) {
    await db.execute(
      `UPDATE mensagens 
       SET lida = TRUE 
       WHERE conversa_id = ? 
       AND remetente_id != ? 
       AND lida = FALSE`,
      [conversaId, usuarioId]
    );
  }

  // Busca conversa por ID
  async findConversaById(conversaId) {
    const [rows] = await db.execute(
      'SELECT * FROM conversas WHERE id = ?',
      [conversaId]
    );
    return rows[0] || null;
  }

  // Verifica se usuário pertence à conversa
  async verificarParticipante(conversaId, usuarioId) {
    const [rows] = await db.execute(
      'SELECT * FROM conversas WHERE id = ? AND (usuario1_id = ? OR usuario2_id = ?)',
      [conversaId, usuarioId, usuarioId]
    );
    return rows.length > 0;
  }

  // Busca contagem de mensagens não lidas
  async countMensagensNaoLidas(usuarioId) {
    const [rows] = await db.execute(
      `SELECT COUNT(*) as total
       FROM mensagens m
       INNER JOIN conversas c ON m.conversa_id = c.id
       WHERE (c.usuario1_id = ? OR c.usuario2_id = ?)
       AND m.remetente_id != ?
       AND m.lida = FALSE`,
      [usuarioId, usuarioId, usuarioId]
    );
    return rows[0]?.total || 0;
  }
}

module.exports = new ChatRepository();


