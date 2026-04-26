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

    return {
      total_policiais: policiais[0].count,
      total_unidades: unidades[0].count,
      total_intencoes: intencoes[0].count,
      verificacoes_pendentes: verificacoes[0].count,
    };
  }

  async findSugestoesPendentes() {
    // ✅ SEGURANÇA: Usar db.execute com parâmetros
    const [sugestoes] = await db.execute("SELECT * FROM sugestoes_unidades WHERE status = ?", ['PENDENTE']);
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
      WHERE p.agente_verificado = 0 AND p.status_verificacao = 'VERIFICADO'
    `;
    // ✅ SEGURANÇA: Usar db.execute mesmo quando a query é construída dinamicamente
    const [verificacoes] = await db.execute(query);
    return verificacoes;
  }

  async updateStatusPolicial(policialId, status) {
    // status pode ser 'VERIFICADO' ou 'REJEITADO'
    // Se for VERIFICADO, marca agente_verificado = 1
    // Se for REJEITADO, mantém agente_verificado = 0 (ou podemos criar uma coluna separada para rejeitado)
    const agenteVerificado = status === 'VERIFICADO' ? 1 : 0;
    const [result] = await db.execute(
      "UPDATE policiais SET agente_verificado = ? WHERE id = ? AND agente_verificado = 0 AND status_verificacao = 'VERIFICADO'", 
      [agenteVerificado, policialId]
    );
    return result.affectedRows > 0;
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

    const limit = parseInt(filters.limit, 10) || 50;
    const offset = parseInt(filters.offset, 10) || 0;

    query += ' ORDER BY p.criado_em DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);

    // ✅ SEGURANÇA: Usar db.execute para queries com parâmetros
    const [policiais] = await db.execute(query, params);
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

    // ✅ SEGURANÇA: Usar db.execute para queries com parâmetros
    const [result] = await db.execute(query, params);
    return result[0].total;
  }

  async updatePolicial(policialId, updateData) {
    const allowedFields = ['status_verificacao', 'embaixador', 'forca_id', 'unidade_atual_id', 'is_moderator', 'is_premium', 'nome', 'email', 'id_funcional', 'qso'];
    const fieldsToUpdate = {};
    
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

    return {
      nota_atualizacao: notaRows.length > 0 ? notaRows[0].valor : '',
      questoes_publico_geral: questoesRows.length > 0 ? (questoesRows[0].valor === '1' || questoesRows[0].valor === 1) : 1,
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
}

module.exports = new AdminRepository();