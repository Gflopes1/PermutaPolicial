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
}

module.exports = new AdminRepository();