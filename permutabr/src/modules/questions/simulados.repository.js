const db = require('../../config/db');

class SimuladosRepository {
  async create(userId, titulo, config) {
    const configJson = JSON.stringify(config);

    const [result] = await db.execute(
      `INSERT INTO simulados (user_id, titulo, config)
       VALUES (?, ?, ?)`,
      [userId, titulo, configJson]
    );

    return result.insertId;
  }

  async addQuestions(simuladoId, questionIds) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      for (let i = 0; i < questionIds.length; i++) {
        await connection.execute(
          `INSERT INTO simulado_questions (simulado_id, question_id, ordem)
           VALUES (?, ?, ?)`,
          [simuladoId, questionIds[i], i + 1]
        );
      }

      await connection.commit();
      return true;
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async findById(id) {
    const [rows] = await db.execute(
      'SELECT * FROM simulados WHERE id = ?',
      [id]
    );
    return rows[0] || null;
  }

  async findQuestionsBySimuladoId(simuladoId) {
    const [rows] = await db.execute(
      `SELECT q.*, sq.ordem
       FROM simulado_questions sq
       JOIN questions q ON sq.question_id = q.id
       WHERE sq.simulado_id = ?
       ORDER BY sq.ordem ASC`,
      [simuladoId]
    );
    return rows;
  }

  async getCurrentQuestion(simuladoId, ordem) {
    const [rows] = await db.execute(
      `SELECT q.*, sq.ordem, s.started_at, s.config
       FROM simulado_questions sq
       JOIN questions q ON sq.question_id = q.id
       JOIN simulados s ON sq.simulado_id = s.id
       WHERE sq.simulado_id = ? AND sq.ordem = ?`,
      [simuladoId, ordem]
    );
    return rows[0] || null;
  }

  async start(simuladoId) {
    await db.execute(
      'UPDATE simulados SET started_at = CURRENT_TIMESTAMP WHERE id = ?',
      [simuladoId]
    );
    return true;
  }

  async finish(simuladoId) {
    await db.execute(
      'UPDATE simulados SET finished_at = CURRENT_TIMESTAMP WHERE id = ?',
      [simuladoId]
    );
    return true;
  }

  async recordAttempt(userId, simuladoId, questionId, answerGiven, correct, timeSpentSeconds) {
    await db.execute(
      `INSERT INTO question_attempts 
       (user_id, simulado_id, question_id, answer_given, correct, time_spent_seconds)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [userId, simuladoId, questionId, answerGiven, correct, timeSpentSeconds]
    );
    return true;
  }

  async getResult(simuladoId, userId) {
    const [attempts] = await db.execute(
      `SELECT 
        qa.*,
        q.pergunta,
        q.alternativas,
        q.resposta_correta,
        q.explicacao,
        q.assunto,
        q.tipo
       FROM question_attempts qa
       JOIN questions q ON qa.question_id = q.id
       WHERE qa.simulado_id = ? AND qa.user_id = ?
       ORDER BY qa.created_at ASC`,
      [simuladoId, userId]
    );

    const total = attempts.length;
    const correct = attempts.filter(a => a.correct).length;
    const accuracy = total > 0 ? (correct / total) * 100 : 0;
    const totalTime = attempts.reduce((sum, a) => sum + (a.time_spent_seconds || 0), 0);

    const [simulado] = await db.execute(
      'SELECT * FROM simulados WHERE id = ?',
      [simuladoId]
    );

    return {
      simulado: simulado[0],
      attempts,
      total,
      correct,
      accuracy: parseFloat(accuracy.toFixed(2)),
      totalTime
    };
  }

  async getDailyAttemptsCount(userId, date) {
    const [rows] = await db.execute(
      `SELECT COUNT(DISTINCT question_id) as count
       FROM question_attempts
       WHERE user_id = ? AND DATE(created_at) = ?`,
      [userId, date]
    );
    return rows[0]?.count || 0;
  }
}

module.exports = new SimuladosRepository();


