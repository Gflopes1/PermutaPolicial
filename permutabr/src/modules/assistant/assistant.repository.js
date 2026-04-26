// /src/modules/assistant/assistant.repository.js

const db = require('../../config/db');

class AssistantRepository {
  /**
   * Salva uma mensagem do usuário ou da IA no banco
   * @param {number} policialId - ID do policial
   * @param {string} texto - Texto da mensagem
   * @param {string} role - 'user' ou 'model'
   * @param {string} sessionId - ID da sessão
   * @param {string} resposta - Resposta da IA (apenas para role='model')
   * @returns {Promise<number>} ID da mensagem criada
   */
  async createMessage(policialId, texto, role = 'user', sessionId = null, resposta = null) {
    try {
      const [result] = await db.execute(
        `INSERT INTO assistant_messages (policial_id, texto, resposta, role, session_id)
         VALUES (?, ?, ?, ?, ?)`,
        [policialId, texto, resposta, role, sessionId]
      );
      
      return result.insertId;
    } catch (error) {
      // Se a tabela não existir, loga o erro e lança exceção informativa
      if (error.code === 'ER_NO_SUCH_TABLE' || error.code === 'ER_BAD_FIELD_ERROR') {
        console.error('❌ Tabela assistant_messages não encontrada ou estrutura incorreta.');
        console.error('📋 Execute a migration: database/migrations/create_assistant_messages_table.sql');
        throw new Error('Tabela assistant_messages não encontrada. Execute a migration SQL primeiro.');
      }
      throw error;
    }
  }

  /**
   * Busca as últimas mensagens de uma sessão
   * @param {number} policialId - ID do policial
   * @param {string} sessionId - ID da sessão
   * @param {number} limit - Número máximo de mensagens (default: 20)
   * @returns {Promise<Array>} Array de mensagens ordenadas por data
   */
  async findMessagesBySession(policialId, sessionId, limit = 20) {
    try {
      const [rows] = await db.execute(
        `SELECT id, texto, resposta, role, session_id, criado_em
         FROM assistant_messages
         WHERE policial_id = ? AND session_id = ?
         ORDER BY criado_em ASC
         LIMIT ?`,
        [policialId, sessionId, limit]
      );
      
      return rows;
    } catch (error) {
      // Se a tabela não existir ou a coluna não existir, retorna array vazio
      if (error.code === 'ER_NO_SUCH_TABLE' || error.code === 'ER_BAD_FIELD_ERROR') {
        console.warn('⚠️ Tabela assistant_messages não encontrada. Execute a migration: database/migrations/create_assistant_messages_table.sql');
        return [];
      }
      throw error;
    }
  }

  /**
   * Busca todas as mensagens de um policial (sem filtro de sessão)
   * Útil para migração ou consultas gerais
   * @param {number} policialId - ID do policial
   * @param {number} limit - Número máximo de mensagens
   * @returns {Promise<Array>} Array de mensagens
   */
  async findMessagesByPolicial(policialId, limit = 20) {
    const [rows] = await db.execute(
      `SELECT id, texto, resposta, role, session_id, criado_em
       FROM assistant_messages
       WHERE policial_id = ?
       ORDER BY criado_em DESC
       LIMIT ?`,
      [policialId, limit]
    );
    
    return rows;
  }

  /**
   * Deleta mensagens antigas de uma sessão (opcional, para limpeza)
   * @param {number} policialId - ID do policial
   * @param {string} sessionId - ID da sessão
   * @returns {Promise<number>} Número de mensagens deletadas
   */
  async deleteMessagesBySession(policialId, sessionId) {
    const [result] = await db.execute(
      `DELETE FROM assistant_messages
       WHERE policial_id = ? AND session_id = ?`,
      [policialId, sessionId]
    );
    
    return result.affectedRows;
  }
}

module.exports = new AssistantRepository();

