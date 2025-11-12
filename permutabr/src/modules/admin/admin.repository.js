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
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      const [sugestoes] = await connection.execute("SELECT * FROM sugestoes_unidades WHERE id = ? AND status = 'PENDENTE' FOR UPDATE", [sugestaoId]);
      if (sugestoes.length === 0) {
        throw new ApiError(404, 'Sugestão não encontrada ou já processada.');
      }
      const sugestao = sugestoes[0];

      await connection.execute(
        'INSERT INTO unidades (nome, municipio_id, forca_id, generica) VALUES (?, ?, ?, FALSE)',
        [sugestao.nome_sugerido, sugestao.municipio_id, sugestao.forca_id]
      );
      await connection.execute("UPDATE sugestoes_unidades SET status = 'APROVADA' WHERE id = ?", [sugestaoId]);

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
        WHERE p.status_verificacao = 'PENDENTE'
    `;
    const [verificacoes] = await db.query(query);
    return verificacoes;
  }

  async updateStatusPolicial(policialId, status) {
    const [result] = await db.execute("UPDATE policiais SET status_verificacao = ? WHERE id = ? AND status_verificacao = 'PENDENTE'", [status, policialId]);
    return result.affectedRows > 0;
  }

  async findAllPoliciais(page = 1, limit = 50, search = '') {
    const offset = (page - 1) * limit;
    let query = `
      SELECT 
        p.id, p.nome, p.email, p.id_funcional, p.qso, p.status_verificacao,
        p.embaixador, p.criado_em, p.posto_graduacao_id,
        f.sigla as forca_sigla, f.nome as forca_nome,
        pg.nome as posto_graduacao_nome,
        u.nome as unidade_atual_nome,
        m.nome as municipio_atual_nome,
        e.sigla as estado_atual_sigla
      FROM policiais p
      LEFT JOIN forcas_policiais f ON p.forca_id = f.id
      LEFT JOIN postos_graduacoes pg ON p.posto_graduacao_id = pg.id
      LEFT JOIN unidades u ON p.unidade_atual_id = u.id
      LEFT JOIN municipios m ON u.municipio_id = m.id
      LEFT JOIN estados e ON m.estado_id = e.id
    `;
    const params = [];

    if (search) {
      query += ` WHERE p.nome LIKE ? OR p.email LIKE ? OR p.id_funcional LIKE ?`;
      const searchTerm = `%${search}%`;
      params.push(searchTerm, searchTerm, searchTerm);
    }

    query += ` ORDER BY p.criado_em DESC LIMIT ? OFFSET ?`;
    params.push(limit, offset);

    const [policiais] = await db.execute(query, params);

    // Contar total
    let countQuery = 'SELECT COUNT(*) as total FROM policiais p';
    const countParams = [];
    if (search) {
      countQuery += ` WHERE p.nome LIKE ? OR p.email LIKE ? OR p.id_funcional LIKE ?`;
      const searchTerm = `%${search}%`;
      countParams.push(searchTerm, searchTerm, searchTerm);
    }
    const [countResult] = await db.execute(countQuery, countParams);

    return {
      policiais,
      total: countResult[0].total,
      page,
      limit,
      totalPages: Math.ceil(countResult[0].total / limit),
    };
  }

  async findAllParceiros() {
    const [parceiros] = await db.query(`
      SELECT id, imagem_url, link_url, ordem, ativo, criado_em
      FROM parceiros
      ORDER BY ordem ASC, criado_em DESC
    `);
    return parceiros;
  }

  async createParceiro(parceiro) {
    const { imagem_url, link_url, ordem, ativo } = parceiro;
    const [result] = await db.execute(
      'INSERT INTO parceiros (imagem_url, link_url, ordem, ativo) VALUES (?, ?, ?, ?)',
      [imagem_url, link_url || null, ordem || 0, ativo !== false]
    );
    return result.insertId;
  }

  async updateParceiro(id, parceiro) {
    const { imagem_url, link_url, ordem, ativo } = parceiro;
    const [result] = await db.execute(
      'UPDATE parceiros SET imagem_url = ?, link_url = ?, ordem = ?, ativo = ? WHERE id = ?',
      [imagem_url, link_url || null, ordem || 0, ativo !== false, id]
    );
    return result.affectedRows > 0;
  }

  async deleteParceiro(id) {
    const [result] = await db.execute('DELETE FROM parceiros WHERE id = ?', [id]);
    return result.affectedRows > 0;
  }

  async getParceirosConfig() {
    const [config] = await db.query("SELECT valor FROM configuracoes WHERE chave = 'exibir_card_parceiros'");
    const exibirCard = config.length > 0 && config[0].valor === '1';
    
    const parceiros = await this.findAllParceiros();
    const parceirosAtivos = parceiros.filter(p => p.ativo);

    return {
      exibir_card: exibirCard,
      parceiros: parceirosAtivos,
    };
  }

  async updateParceirosConfig(exibirCard) {
    const [result] = await db.execute(
      `INSERT INTO configuracoes (chave, valor) VALUES ('exibir_card_parceiros', ?)
       ON DUPLICATE KEY UPDATE valor = ?`,
      [exibirCard ? '1' : '0', exibirCard ? '1' : '0']
    );
    return true;
  }
}

module.exports = new AdminRepository();