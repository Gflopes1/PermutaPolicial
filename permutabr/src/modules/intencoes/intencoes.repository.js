// /src/modules/intencoes/intencoes.repository.js

const db = require('../../config/db');

class IntencoesRepository {
  async findByPolicialId(policialId) {
    const query = `
        SELECT
            i.id, i.prioridade, i.tipo_intencao,
            i.estado_id, i.municipio_id, i.unidade_id,
            i.unidade_atual_id, i.municipio_atual_id,
            e.sigla as estado_sigla,
            m.nome as municipio_nome,
            u.nome as unidade_nome,
            u_atual.nome as unidade_atual_nome,
            m_atual.nome as municipio_atual_nome
        FROM intencoes i
        LEFT JOIN estados e ON i.estado_id = e.id
        LEFT JOIN municipios m ON i.municipio_id = m.id
        LEFT JOIN unidades u ON i.unidade_id = u.id
        LEFT JOIN unidades u_atual ON i.unidade_atual_id = u_atual.id
        LEFT JOIN municipios m_atual ON i.municipio_atual_id = m_atual.id
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

      // 1. Busca o perfil do policial para obter o local atual
      const [policialRows] = await connection.execute(
        'SELECT unidade_atual_id, municipio_atual_id FROM policiais WHERE id = ?',
        [policialId]
      );
      
      if (policialRows.length === 0) {
        throw new Error('Policial não encontrado');
      }
      
      const policial = policialRows[0];
      let unidadeAtualId = policial.unidade_atual_id;
      let municipioAtualId = policial.municipio_atual_id;
      
      // Se não tem municipio_atual_id direto, tenta pegar da unidade
      if (!municipioAtualId && unidadeAtualId) {
        const [unidadeRows] = await connection.execute(
          'SELECT municipio_id FROM unidades WHERE id = ?',
          [unidadeAtualId]
        );
        if (unidadeRows.length > 0) {
          municipioAtualId = unidadeRows[0].municipio_id;
        }
      }

      // 2. Apagar todas as intenções antigas do policial
      await connection.execute('DELETE FROM intencoes WHERE policial_id = ?', [policialId]);

      // 3. Inserir as novas intenções, se houver alguma
      if (intencoes.length > 0) {
        const query = `
            INSERT INTO intencoes (policial_id, prioridade, tipo_intencao, estado_id, municipio_id, unidade_id, unidade_atual_id, municipio_atual_id) 
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
            i.unidade_id || null,
            unidadeAtualId || null,
            municipioAtualId || null
        ]);
        await connection.query(query, [values]);
      }

      // 4. Se tudo deu certo, confirma a transação
      await connection.commit();
    } catch (error) {
      // 5. Se algo deu errado, desfaz todas as operações
      await connection.rollback();
      // Lança o erro para a camada de serviço
      throw error;
    } finally {
      // 6. Libera a conexão de volta para o pool, ocorrendo erro ou não
      connection.release();
    }
  }

  async deleteAll(policialId) {
    const [result] = await db.execute('DELETE FROM intencoes WHERE policial_id = ?', [policialId]);
    return result.affectedRows;
  }
}

module.exports = new IntencoesRepository();