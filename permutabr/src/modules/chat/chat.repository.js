// /src/modules/chat/chat.repository.js

const db = require('../../config/db');

class ChatRepository {
  // Busca ou cria uma conversa entre dois usuários
  async findOrCreateConversa(usuario1Id, usuario2Id, anonima = false) {
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

    // Cria nova conversa (anonima se especificado)
    const [result] = await db.execute(
      'INSERT INTO conversas (usuario1_id, usuario2_id, anonima, iniciada_por) VALUES (?, ?, ?, ?)',
      [id1, id2, anonima, anonima ? usuario1Id : null]
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
        c.anonima,
        c.iniciada_por,
        c.remetente_revelado,
        CASE 
          WHEN c.usuario1_id = ? THEN c.usuario2_id
          ELSE c.usuario1_id
        END as outro_usuario_id,
        CASE 
          -- Se é anônima e não foi revelado E o usuário atual é o iniciador, mostra "Usuário não identificado"
          -- (o iniciador não vê os dados do destinatário até ele aceitar)
          WHEN c.anonima = 1 AND c.remetente_revelado = 0 AND c.iniciada_por = ? THEN 'Usuário não identificado'
          -- Se é anônima e não foi revelado E o usuário atual é o destinatário, mostra nome do iniciador
          -- (o destinatário sempre vê os dados do iniciador desde o início)
          WHEN c.anonima = 1 AND c.remetente_revelado = 0 AND c.iniciada_por != ? AND c.iniciada_por IS NOT NULL THEN p.nome
          ELSE p.nome
        END as outro_usuario_nome,
        CASE 
          -- Se é anônima e não foi revelado E o usuário atual é o iniciador, não mostra email
          -- (o iniciador não vê os dados do destinatário até ele aceitar)
          WHEN c.anonima = 1 AND c.remetente_revelado = 0 AND c.iniciada_por = ? THEN NULL
          -- Se é anônima e não foi revelado E o usuário atual é o destinatário, mostra email do iniciador
          -- (o destinatário sempre vê os dados do iniciador desde o início)
          WHEN c.anonima = 1 AND c.remetente_revelado = 0 AND c.iniciada_por != ? AND c.iniciada_por IS NOT NULL THEN p.email
          ELSE p.email
        END as outro_usuario_email,
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
    
    const [rows] = await db.execute(query, [usuarioId, usuarioId, usuarioId, usuarioId, usuarioId, usuarioId, usuarioId, usuarioId, usuarioId]);
    return rows;
  }

  // Busca mensagens de uma conversa
  async findMensagensByConversa(conversaId, usuarioId, limit = 50, offset = 0) {
    // Busca informações da conversa para verificar se é anônima
    const conversa = await this.findConversaById(conversaId);
    const isAnonima = conversa?.anonima || false;
    const remetenteRevelado = conversa?.remetente_revelado || false;
    const iniciadaPor = conversa?.iniciada_por;
    
    // Determina se o usuário atual é quem iniciou a conversa anônima
    const isRemetenteOriginal = isAnonima && iniciadaPor && iniciadaPor === usuarioId;
    
    // Se não é anônima ou já foi revelado, busca normalmente
    if (!isAnonima || remetenteRevelado || !iniciadaPor) {
      const query = `
        SELECT 
          m.id,
          m.conversa_id,
          m.remetente_id,
          m.mensagem,
          m.lida,
          m.criado_em,
          p.nome as remetente_nome,
          p.email as remetente_email,
          1 as remetente_identificado
        FROM mensagens m
        LEFT JOIN policiais p ON m.remetente_id = p.id
        WHERE m.conversa_id = ?
        ORDER BY m.criado_em DESC
        LIMIT ? OFFSET ?
      `;
      const [rows] = await db.execute(query, [conversaId, limit, offset]);
      return rows.reverse();
    }
    
    // Conversa anônima: Lógica de visibilidade
    // - Mensagens do INICIADOR (solicitante): sempre visíveis para o DESTINATÁRIO, ocultas para o próprio iniciador até aceitar
    // - Mensagens do DESTINATÁRIO (solicitado): ocultas até aceitar compartilhar dados
    const remetenteReveladoInt = remetenteRevelado ? 1 : 0;
    const isUsuarioIniciador = iniciadaPor === usuarioId;
    
    const query = `
      SELECT 
        m.id,
        m.conversa_id,
        m.remetente_id,
        m.mensagem,
        m.lida,
        m.criado_em,
        CASE 
          -- Se a mensagem é do DESTINATÁRIO e não foi revelado, oculta para o iniciador
          WHEN m.remetente_id != ? AND ? = 0 AND ? = 1 THEN 'Usuário não identificado'
          -- Se a mensagem é do INICIADOR, sempre mostra para o destinatário
          -- Se a mensagem é do DESTINATÁRIO e foi revelado, mostra normalmente
          ELSE p.nome
        END as remetente_nome,
        CASE 
          -- Se a mensagem é do DESTINATÁRIO e não foi revelado, oculta email para o iniciador
          WHEN m.remetente_id != ? AND ? = 0 AND ? = 1 THEN NULL
          -- Se a mensagem é do INICIADOR, sempre mostra email para o destinatário
          -- Se a mensagem é do DESTINATÁRIO e foi revelado, mostra normalmente
          ELSE p.email
        END as remetente_email,
        CASE 
          -- Se a mensagem é do DESTINATÁRIO e não foi revelado, marca como não identificado para o iniciador
          WHEN m.remetente_id != ? AND ? = 0 AND ? = 1 THEN 0
          -- Caso contrário, identificado
          ELSE 1
        END as remetente_identificado
      FROM mensagens m
      LEFT JOIN policiais p ON m.remetente_id = p.id
      WHERE m.conversa_id = ?
      ORDER BY m.criado_em DESC
      LIMIT ? OFFSET ?
    `;
    
    const [rows] = await db.execute(query, [
      iniciadaPor, remetenteReveladoInt, isUsuarioIniciador ? 1 : 0,
      iniciadaPor, remetenteReveladoInt, isUsuarioIniciador ? 1 : 0,
      iniciadaPor, remetenteReveladoInt, isUsuarioIniciador ? 1 : 0,
      conversaId, limit, offset
    ]);
    return rows.reverse(); // Inverte para mostrar do mais antigo ao mais recente
  }

  // Cria uma nova mensagem
  async createMensagem(conversaId, remetenteId, mensagem) {
    // Busca informações da conversa
    const conversa = await this.findConversaById(conversaId);
    const isAnonima = conversa?.anonima || false;
    const remetenteRevelado = conversa?.remetente_revelado || false;
    const iniciadaPor = conversa?.iniciada_por;
    
    // Verifica se é a primeira mensagem da conversa
    const [mensagensExistentes] = await db.execute(
      'SELECT COUNT(*) as total FROM mensagens WHERE conversa_id = ?',
      [conversaId]
    );
    const isPrimeiraMensagem = mensagensExistentes[0].total === 0;
    
    // Se é a primeira mensagem, é anônima, e o remetente é o iniciador (solicitante),
    // inclui informações do remetente automaticamente para que o destinatário saiba com quem está conversando
    let mensagemFinal = mensagem.trim();
    if (isPrimeiraMensagem && isAnonima && iniciadaPor && remetenteId === iniciadaPor) {
      // Busca informações completas do remetente (solicitante)
      const policiaisRepository = require('../policiais/policiais.repository');
      const remetente = await policiaisRepository.findProfileById(remetenteId);
      
      if (remetente) {
        const informacoes = [];
        if (remetente.nome) informacoes.push(`Nome: ${remetente.nome}`);
        if (remetente.posto_graduacao_nome) informacoes.push(`Posto/Graduação: ${remetente.posto_graduacao_nome}`);
        if (remetente.municipio_atual_nome && remetente.estado_atual_sigla) {
          informacoes.push(`Cidade: ${remetente.municipio_atual_nome} - ${remetente.estado_atual_sigla}`);
        }
        if (remetente.unidade_atual_nome) informacoes.push(`Unidade: ${remetente.unidade_atual_nome}`);
        
        if (informacoes.length > 0) {
          mensagemFinal = `${informacoes.join('\n')}\n\n${mensagem.trim()}`;
        }
      }
    }
    
    const [result] = await db.execute(
      'INSERT INTO mensagens (conversa_id, remetente_id, mensagem) VALUES (?, ?, ?)',
      [conversaId, remetenteId, mensagemFinal]
    );

    // Atualiza o timestamp da conversa
    await db.execute(
      'UPDATE conversas SET atualizado_em = CURRENT_TIMESTAMP WHERE id = ?',
      [conversaId]
    );

    // Busca a mensagem criada com informações do remetente
    // Sempre retorna com dados completos, pois o remetente já sabe quem é
    // A filtragem de dados acontece apenas na busca de mensagens (findMensagensByConversa)
    const [mensagemCriada] = await db.execute(
      `SELECT 
        m.id,
        m.conversa_id,
        m.remetente_id,
        m.mensagem,
        m.lida,
        m.criado_em,
        p.nome as remetente_nome,
        p.email as remetente_email,
        1 as remetente_identificado
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

  // Aceita compartilhar dados em conversa anônima
  async aceitarCompartilharDados(conversaId) {
    await db.execute(
      'UPDATE conversas SET remetente_revelado = TRUE WHERE id = ?',
      [conversaId]
    );
  }

  // Exclui uma conversa e todas as mensagens
  async excluirConversa(conversaId) {
    // Exclui mensagens primeiro (devido à foreign key)
    await db.execute('DELETE FROM mensagens WHERE conversa_id = ?', [conversaId]);
    // Exclui a conversa
    await db.execute('DELETE FROM conversas WHERE id = ?', [conversaId]);
  }
}

module.exports = new ChatRepository();




