// /src/modules/intencoes/intencoes.repository.js

const db = require('../../config/db');

class IntencoesRepository {
  async findByPolicialId(policialId) {
    const query = `
        SELECT
            i.id, i.prioridade, i.tipo_intencao,
            i.estado_id, i.municipio_id, i.unidade_id,
            e.sigla as estado_sigla,
            m.nome as municipio_nome,
            u.nome as unidade_nome
        FROM intencoes i
        LEFT JOIN estados e ON i.estado_id = e.id
        LEFT JOIN municipios m ON i.municipio_id = m.id
        LEFT JOIN unidades u ON i.unidade_id = u.id
        WHERE i.policial_id = ?
        ORDER BY i.prioridade ASC
    `;
    const [intencoes] = await db.execute(query, [policialId]);
    return intencoes;
  }

  async replaceAll(policialId, intencoes) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      // 1. Apagar todas as intenções antigas do policial
      await connection.execute('DELETE FROM intencoes WHERE policial_id = ?', [policialId]);

      // 2. Inserir as novas intenções, se houver alguma
      if (intencoes.length > 0) {
        const query = `
            INSERT INTO intencoes (policial_id, prioridade, tipo_intencao, estado_id, municipio_id, unidade_id) 
            VALUES ?
        `;
        // Mapeia o array de objetos para um array de arrays, que é o formato
        // que o driver do mysql2 espera para inserções em massa.
        const values = intencoes.map(i => [
            policialId,
            i.prioridade,
            i.tipo_intencao,
            i.estado_id || null,
            i.municipio_id || null,
            i.unidade_id || null
        ]);
        await connection.query(query, [values]);
      }

      // 3. Se tudo deu certo, confirma a transação
      await connection.commit();
    } catch (error) {
      // 4. Se algo deu errado, desfaz todas as operações
      await connection.rollback();
      // Lança o erro para a camada de serviço
      throw error;
    } finally {
      // 5. Libera a conexão de volta para o pool, ocorrendo erro ou não
      connection.release();
    }
  }

  async deleteAll(policialId) {
    const [result] = await db.execute('DELETE FROM intencoes WHERE policial_id = ?', [policialId]);
    return result.affectedRows;
  }
}

module.exports = new IntencoesRepository();