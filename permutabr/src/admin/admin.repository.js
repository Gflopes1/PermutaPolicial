// /src/modules/admin/admin.repository.js

const db = require('../../config/db');
const ApiError = require('../../core/utils/ApiError');

class AdminRepository {
  async getEstatisticas() {
    // ✅ SEGURANÇA: Usar db.execute mesmo para queries sem parâmetros
    const [policiais] = await db.execute('SELECT COUNT(*) as count FROM policiais');
    const [unidades] = await db.execute('SELECT COUNT(*) as count FROM unidades');
    const [intencoes] = await db.execute('SELECT COUNT(*) as count FROM intencoes');
    const [verificacoes] = await db.execute("SELECT COUNT(*) as count FROM policiais WHERE agente_verificado = 0 AND status_verificacao = ?", ['VERIFICADO']);
    let totalPermutasConcluidas = 0;
    let totalRelatosPendentes = 0;
    try {
      const [permutasConcluidas] = await db.execute('SELECT COUNT(*) as count FROM permutas_concluidas_feedback');
      totalPermutasConcluidas = permutasConcluidas[0]?.count || 0;
    } catch (_) {
      totalPermutasConcluidas = 0;
    }
    try {
      const [relatosPendentes] = await db.execute(
        "SELECT COUNT(*) as count FROM problema_relatos WHERE status = 'PENDENTE'"
      );
      totalRelatosPendentes = relatosPendentes[0]?.count || 0;
    } catch (_) {
      totalRelatosPendentes = 0;
    }

    return {
      total_policiais: policiais[0].count,
      total_unidades: unidades[0].count,
      total_intencoes: intencoes[0].count,
      verificacoes_pendentes: verificacoes[0].count,
      total_permutas_concluidas: totalPermutasConcluidas,
      total_relatos_pendentes: totalRelatosPendentes,
    };
  }

  async findPermutasConcluidasFeedback() {
    try {
    const [rows] = await db.execute(`
      SELECT
        f.id,
        f.policial_id,
        f.quantidade_intencoes,
        f.origem,
        f.criado_em,
        p.nome as policial_nome,
        p.email as policial_email,
        fp.sigla as forca_sigla
      FROM permutas_concluidas_feedback f
      JOIN policiais p ON p.id = f.policial_id
      LEFT JOIN forcas_policiais fp ON fp.id = p.forca_id
      ORDER BY f.criado_em DESC
      LIMIT 200
    `);
    return rows;
    } catch (_) {
      return [];
    }
  }

  async findSugestoesPendentes() {
    // ✅ SEGURANÇA: Usar db.execute com parâmetros
    const [sugestoes] = await db.execute("SELECT * FROM sugestoes_unidades WHERE status = ?", ['PENDENTE']);
    return sugestoes;
  }

  async aprovarSugestao(sugestaoId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      const [sugestoes] = await connection.execute(
        "SELECT * FROM sugestoes_unidades WHERE id = ? AND status = 'PENDENTE'",
        [sugestaoId]
      );
      if (sugestoes.length === 0) {
        throw new ApiError(404, 'Sugestão não encontrada ou já processada.');
      }
      const sugestao = sugestoes[0];

      await connection.execute(
        'INSERT INTO unidades (nome, municipio_id, forca_id, generica) VALUES (?, ?, ?, FALSE)',
        [sugestao.nome_sugerido, sugestao.municipio_id, sugestao.forca_id]
      );

      const [updateResult] = await connection.execute(
        "UPDATE sugestoes_unidades SET status = 'APROVADA' WHERE id = ? AND status = 'PENDENTE'",
        [sugestaoId]
      );
      if (updateResult.affectedRows === 0) {
        throw new ApiError(409, 'Sugestão já foi processada por outro administrador.');
      }

      await connection.commit();
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
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
      WHERE p.agente_verificado = 0 AND p.status_verificacao = 'VERIFICADO'
    `;
    // ✅ SEGURANÇA: Usar db.execute mesmo quando a query é construída dinamicamente
    const [verificacoes] = await db.execute(query);
    return verificacoes;
  }

  async updateStatusPolicial(policialId, status) {
    if (status === 'VERIFICADO') {
      const [result] = await db.execute(
        "UPDATE policiais SET agente_verificado = 1 WHERE id = ? AND agente_verificado = 0 AND status_verificacao = 'VERIFICADO'",
        [policialId]
      );
      return result.affectedRows > 0;
    }

    if (status === 'REJEITADO') {
      const [result] = await db.execute(
        "UPDATE policiais SET status_verificacao = 'REJEITADO', agente_verificado = 0 WHERE id = ? AND agente_verificado = 0 AND status_verificacao = 'VERIFICADO'",
        [policialId]
      );
      return result.affectedRows > 0;
    }

    return false;
  }

  async findAllPoliciais(filters = {}) {
    let query = `
      SELECT 
        p.id, p.nome, p.email, p.id_funcional, p.qso, p.status_verificacao,
        p.criado_em, p.embaixador,
        COALESCE(p.is_moderator, p.embaixador, 0) as is_moderator,
        COALESCE(p.is_premium, 0) as is_premium,
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

    const limit = Math.min(parseInt(filters.limit, 10) || 50, 100);
    const offset = Math.max(parseInt(filters.offset, 10) || 0, 0);

    query += ' ORDER BY p.criado_em DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);

    const [policiais] = await db.execute(query, params);
    return policiais;
  }

  async findPolicialById(policialId) {
    const [rows] = await db.execute(
      'SELECT id, embaixador, is_moderator FROM policiais WHERE id = ?',
      [policialId]
    );
    return rows[0] || null;
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

    // ✅ SEGURANÇA: Usar db.execute para queries com parâmetros
    const [result] = await db.execute(query, params);
    return result[0].total;
  }

  async updatePolicial(policialId, updateData) {
    const allowedFields = [
      'status_verificacao', 'embaixador', 'forca_id', 'unidade_atual_id', 'is_moderator',
      'is_premium', 'nome', 'email', 'id_funcional', 'qso', 'destaque_ate', 'alertas_match_ativo',
    ];
    const fieldsToUpdate = {};

    if (updateData.destaque_dias !== undefined) {
      const dias = parseInt(updateData.destaque_dias, 10);
      if (!dias || dias <= 0) {
        fieldsToUpdate.destaque_ate = null;
      } else {
        const ate = new Date();
        ate.setDate(ate.getDate() + dias);
        fieldsToUpdate.destaque_ate = ate;
      }
    }
    
    for (const field of allowedFields) {
      if (updateData[field] !== undefined) {
        fieldsToUpdate[field] = updateData[field];
      }
    }

    // Sincroniza embaixador e is_moderator (admin e moderador = embaixador)
    if (updateData['is_moderator'] !== undefined) {
      fieldsToUpdate['embaixador'] = updateData['is_moderator'];
    } else if (updateData['embaixador'] !== undefined) {
      fieldsToUpdate['is_moderator'] = updateData['embaixador'];
    }

    if (Object.keys(fieldsToUpdate).length === 0) {
      return false;
    }

    // Se está marcando como premium, cria/atualiza assinatura
    if (updateData['is_premium'] !== undefined) {
      const isPremium = updateData['is_premium'] === 1 || updateData['is_premium'] === true;
      
      if (isPremium) {
        // Verifica se já existe assinatura ativa
        const [existingSubs] = await db.execute(
          `SELECT id FROM user_subscriptions 
           WHERE user_id = ? AND status = 'active' 
           LIMIT 1`,
          [policialId]
        );

        if (existingSubs.length === 0) {
          // Cria uma assinatura manual (admin)
          const startAt = new Date();
          const endAt = new Date();
          endAt.setFullYear(endAt.getFullYear() + 1); // 1 ano de validade

          await db.execute(
            `INSERT INTO user_subscriptions 
             (user_id, plan_id, status, start_at, end_at, provider, provider_subscription_id, auto_renew)
             VALUES (?, 'premium', 'active', ?, ?, 'admin', 'manual_${policialId}', 0)`,
            [policialId, startAt, endAt]
          );
        } else {
          // Atualiza assinatura existente para ativa
          await db.execute(
            `UPDATE user_subscriptions 
             SET status = 'active', 
                 start_at = COALESCE(start_at, NOW()),
                 end_at = COALESCE(end_at, DATE_ADD(NOW(), INTERVAL 1 YEAR))
             WHERE user_id = ? AND id = ?`,
            [policialId, existingSubs[0].id]
          );
        }
      } else {
        // Se está desmarcando premium, cancela assinaturas ativas
        await db.execute(
          `UPDATE user_subscriptions 
           SET status = 'canceled', 
               canceled_at = NOW(),
               cancel_reason = 'Cancelado manualmente pelo admin'
           WHERE user_id = ? AND status = 'active'`,
          [policialId]
        );
      }
    }

    const setClause = Object.keys(fieldsToUpdate).map(key => `${key} = ?`).join(', ');
    const values = [...Object.values(fieldsToUpdate), policialId];
    const query = `UPDATE policiais SET ${setClause} WHERE id = ?`;

    const [result] = await db.execute(query, values);
    return result.affectedRows > 0;
  }

  async getConfiguracoes() {
    // Busca configurações da tabela configuracoes_gerais (formato chave-valor)
    const [notaRows] = await db.execute(
      'SELECT valor FROM configuracoes_gerais WHERE chave = ?',
      ['nota_atualizacao']
    );
    const [questoesRows] = await db.execute(
      'SELECT valor FROM configuracoes_gerais WHERE chave = ?',
      ['questoes_publico_geral']
    );
    const [whatsappRows] = await db.execute(
      'SELECT valor FROM configuracoes_gerais WHERE chave = ?',
      ['editais_whatsapp_numero']
    );
    const [whatsappMsgRows] = await db.execute(
      'SELECT valor FROM configuracoes_gerais WHERE chave = ?',
      ['editais_whatsapp_mensagem']
    );

    return {
      nota_atualizacao: notaRows.length > 0 ? notaRows[0].valor : '',
      questoes_publico_geral: questoesRows.length > 0 ? (questoesRows[0].valor === '1' || questoesRows[0].valor === 1) : 1,
      editais_whatsapp_numero: whatsappRows.length > 0 ? whatsappRows[0].valor : '5551986200626',
      editais_whatsapp_mensagem: whatsappMsgRows.length > 0 ? whatsappMsgRows[0].valor : 'Olá, gostaria de enviar um edital de transferência ou de novos agentes para adicionar ao site',
    };
  }

  async updateConfiguracoes(updateData) {
    const updates = [];

    // Atualiza nota_atualizacao
    if (updateData['nota_atualizacao'] !== undefined) {
      await db.execute(
        'INSERT INTO configuracoes_gerais (chave, valor) VALUES (?, ?) ON DUPLICATE KEY UPDATE valor = ?',
        ['nota_atualizacao', updateData['nota_atualizacao'], updateData['nota_atualizacao']]
      );
      updates.push('nota_atualizacao');
    }

    // Atualiza questoes_publico_geral
    if (updateData['questoes_publico_geral'] !== undefined) {
      const valor = updateData['questoes_publico_geral'] === 1 || updateData['questoes_publico_geral'] === true ? '1' : '0';
      await db.execute(
        'INSERT INTO configuracoes_gerais (chave, valor) VALUES (?, ?) ON DUPLICATE KEY UPDATE valor = ?',
        ['questoes_publico_geral', valor, valor]
      );
      updates.push('questoes_publico_geral');
    }

    if (updateData['editais_whatsapp_numero'] !== undefined) {
      await db.execute(
        'INSERT INTO configuracoes_gerais (chave, valor) VALUES (?, ?) ON DUPLICATE KEY UPDATE valor = ?',
        ['editais_whatsapp_numero', updateData['editais_whatsapp_numero'], updateData['editais_whatsapp_numero']]
      );
      updates.push('editais_whatsapp_numero');
    }

    if (updateData['editais_whatsapp_mensagem'] !== undefined) {
      await db.execute(
        'INSERT INTO configuracoes_gerais (chave, valor) VALUES (?, ?) ON DUPLICATE KEY UPDATE valor = ?',
        ['editais_whatsapp_mensagem', updateData['editais_whatsapp_mensagem'], updateData['editais_whatsapp_mensagem']]
      );
      updates.push('editais_whatsapp_mensagem');
    }

    return updates.length > 0;
  }

  async getPremiumUsers(filters = {}) {
    let query = `
      SELECT 
        p.id,
        p.nome,
        p.email,
        p.id_funcional,
        p.is_premium,
        us.id as subscription_id,
        us.plan_id,
        us.status as subscription_status,
        us.start_at,
        us.end_at,
        us.provider,
        us.provider_subscription_id,
        us.auto_renew,
        us.canceled_at,
        us.cancel_reason,
        us.created_at as subscription_created_at,
        f.sigla as forca_sigla,
        f.nome as forca_nome
      FROM policiais p
      INNER JOIN user_subscriptions us ON p.id = us.user_id
      LEFT JOIN forcas_policiais f ON p.forca_id = f.id
      WHERE 1=1
    `;
    const params = [];

    // Filtro por status da assinatura
    if (filters.status) {
      query += ' AND us.status = ?';
      params.push(filters.status);
    } else {
      // Por padrão, mostra apenas ativas ou expiradas recentemente
      query += ' AND us.status IN ("active", "expired", "canceled")';
    }

    // Filtro por provedor
    if (filters.provider) {
      query += ' AND us.provider = ?';
      params.push(filters.provider);
    }

    // Busca por nome/email
    if (filters.search) {
      query += ' AND (p.nome LIKE ? OR p.email LIKE ? OR p.id_funcional LIKE ?)';
      const searchTerm = `%${filters.search}%`;
      params.push(searchTerm, searchTerm, searchTerm);
    }

    const limit = parseInt(filters.limit, 10) || 50;
    const offset = parseInt(filters.offset, 10) || 0;

    query += ' ORDER BY us.created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);

    // ✅ SEGURANÇA: Usar db.execute para queries com parâmetros
    const [users] = await db.execute(query, params);
    return users;
  }

  async countPremiumUsers(filters = {}) {
    let query = `
      SELECT COUNT(*) as total
      FROM policiais p
      INNER JOIN user_subscriptions us ON p.id = us.user_id
      WHERE 1=1
    `;
    const params = [];

    if (filters.status) {
      query += ' AND us.status = ?';
      params.push(filters.status);
    } else {
      query += ' AND us.status IN ("active", "expired", "canceled")';
    }

    if (filters.provider) {
      query += ' AND us.provider = ?';
      params.push(filters.provider);
    }

    if (filters.search) {
      query += ' AND (p.nome LIKE ? OR p.email LIKE ? OR p.id_funcional LIKE ?)';
      const searchTerm = `%${filters.search}%`;
      params.push(searchTerm, searchTerm, searchTerm);
    }

    // ✅ SEGURANÇA: Usar db.execute para queries com parâmetros
    const [result] = await db.execute(query, params);
    return result[0].total;
  }

  async findBroadcastRecipients() {
    const [rows] = await db.execute(
      `SELECT id, nome, email FROM policiais
       WHERE email IS NOT NULL AND TRIM(email) != ''
         AND status_verificacao IN ('VERIFICADO', 'NAO_VERIFICADO')`
    );
    return rows;
  }

  async deletePolicial(policialId) {
    const { cleanupPolicialDependencies } = require('../../core/utils/policial-cleanup');
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      const [existing] = await connection.execute('SELECT id FROM policiais WHERE id = ?', [policialId]);
      if (existing.length === 0) {
        await connection.rollback();
        return false;
      }

      await cleanupPolicialDependencies(connection, policialId);

      const [result] = await connection.execute('DELETE FROM policiais WHERE id = ?', [policialId]);
      await connection.commit();
      return result.affectedRows > 0;
    } catch (error) {
      await connection.rollback();
      if (error.code === 'ER_ROW_IS_REFERENCED_2') {
        throw new ApiError(
          409,
          'Não foi possível excluir a conta pois existem registros vinculados. Entre em contato com o suporte técnico.',
          null,
          'DELETE_POLICIAL_REFERENCED'
        );
      }
      throw error;
    } finally {
      connection.release();
    }
  }
}

module.exports = new AdminRepository();