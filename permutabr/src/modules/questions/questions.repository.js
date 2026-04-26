const db = require('../../config/db');

class QuestionsRepository {
  async findAll({ assunto, subassunto, tipo, page = 1, perPage = 20, search, apenasAprovadas = true }) {
    const offset = (page - 1) * perPage;
    let whereConditions = [];
    let params = [];

    // Por padrão, mostrar apenas questões aprovadas
    if (apenasAprovadas) {
      whereConditions.push('aprovada = TRUE');
    }

    if (assunto) {
      whereConditions.push('assunto = ?');
      params.push(assunto);
    }

    if (subassunto) {
      whereConditions.push('subassunto = ?');
      params.push(subassunto);
    }

    if (tipo) {
      whereConditions.push('tipo = ?');
      params.push(tipo);
    }

    if (search) {
      whereConditions.push('MATCH(pergunta) AGAINST(? IN BOOLEAN MODE)');
      params.push(search);
    }

    const whereClause = whereConditions.length > 0 
      ? `WHERE ${whereConditions.join(' AND ')}`
      : '';

    const query = `
      SELECT * FROM questions
      ${whereClause}
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    `;

    params.push(perPage, offset);

    const [rows] = await db.execute(query, params);

    const countQuery = `
      SELECT COUNT(*) as total FROM questions ${whereClause}
    `;
    const countParams = apenasAprovadas && whereConditions.length > 1
      ? params.slice(0, -2)
      : params.slice(0, -2);
    const [countRows] = await db.execute(countQuery, countParams);
    const total = countRows[0]?.total || 0;

    return { data: rows, total, page, perPage };
  }

  async findById(id) {
    const [rows] = await db.execute(
      'SELECT * FROM questions WHERE id = ?',
      [id]
    );
    return rows[0] || null;
  }

  // Busca subassuntos por assunto
  async findSubassuntosByAssunto(assunto) {
    const query = `
      SELECT DISTINCT subassunto 
      FROM questions 
      WHERE assunto = ? AND subassunto IS NOT NULL AND subassunto != ''
      ORDER BY subassunto ASC
    `;
    const [rows] = await db.execute(query, [assunto]);
    return rows.map(row => row.subassunto);
  }

  // Busca todos os assuntos únicos
  async findAllAssuntos() {
    const query = `
      SELECT DISTINCT assunto 
      FROM questions 
      WHERE assunto IS NOT NULL AND assunto != ''
      ORDER BY assunto ASC
    `;
    const [rows] = await db.execute(query);
    return rows.map(row => row.assunto);
  }

  async findRandomBySubjects(subjectsConfig, excludeIds = [], { subassuntos = [], tipo = null } = {}) {
    const questions = [];
    const excludeClause = excludeIds.length > 0 
      ? `AND id NOT IN (${excludeIds.map(() => '?').join(',')})`
      : '';

    let subassuntoClause = '';
    let tipoClause = '';
    const extraParams = [];

    if (subassuntos.length > 0) {
      subassuntoClause = `AND subassunto IN (${subassuntos.map(() => '?').join(',')})`;
      extraParams.push(...subassuntos);
    }

    if (tipo) {
      tipoClause = 'AND tipo = ?';
      extraParams.push(tipo);
    }

    // Se subjectsConfig estiver vazio (caso random), busca de todas as questões
    if (Object.keys(subjectsConfig).length === 0) {
      const query = `
        SELECT * FROM questions
        WHERE aprovada = TRUE ${excludeClause} ${subassuntoClause} ${tipoClause}
        ORDER BY RAND()
        LIMIT 1000
      `;
      
      const params = excludeIds.length > 0 
        ? [...excludeIds, ...extraParams]
        : [...extraParams];

      const [rows] = await db.execute(query, params);
      return rows;
    }

    // Caso by_subject, busca por assunto
    for (const [assunto, count] of Object.entries(subjectsConfig)) {
      const query = `
        SELECT * FROM questions
        WHERE assunto = ? AND aprovada = TRUE ${excludeClause} ${subassuntoClause} ${tipoClause}
        ORDER BY RAND()
        LIMIT ?
      `;
      
      const params = excludeIds.length > 0 
        ? [assunto, ...excludeIds, ...extraParams, count]
        : [assunto, ...extraParams, count];

      const [rows] = await db.execute(query, params);
      questions.push(...rows);
    }

    return questions;
  }

  async create(questionData) {
    const {
      pergunta,
      alternativas,
      resposta_correta,
      explicacao,
      assunto,
      subassunto,
      tipo,
      origem
    } = questionData;

    const alternativasJson = JSON.stringify(alternativas);

    const [result] = await db.execute(
      `INSERT INTO questions 
       (pergunta, alternativas, resposta_correta, explicacao, assunto, subassunto, tipo, origem)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [pergunta, alternativasJson, resposta_correta, explicacao, assunto, subassunto, tipo, origem]
    );

    return result.insertId;
  }

  async update(id, questionData) {
    const {
      pergunta,
      alternativas,
      resposta_correta,
      explicacao,
      assunto,
      subassunto,
      tipo,
      origem
    } = questionData;

    const alternativasJson = JSON.stringify(alternativas);

    await db.execute(
      `UPDATE questions SET
       pergunta = ?, alternativas = ?, resposta_correta = ?, explicacao = ?,
       assunto = ?, subassunto = ?, tipo = ?, origem = ?
       WHERE id = ?`,
      [pergunta, alternativasJson, resposta_correta, explicacao, assunto, subassunto, tipo, origem, id]
    );

    return true;
  }

  async delete(id) {
    await db.execute('DELETE FROM questions WHERE id = ?', [id]);
    return true;
  }

  // Modo Prática - Buscar próxima questão não respondida
  async findNextUnanswered(userId, { subjects = [], subassuntos = [], tipo = null } = {}) {
    let whereConditions = ['q.aprovada = TRUE'];
    let params = [];

    // Filtrar por assuntos se fornecidos
    if (subjects.length > 0) {
      whereConditions.push(`q.assunto IN (${subjects.map(() => '?').join(',')})`);
      params.push(...subjects);
    }

    // Filtrar por subassuntos se fornecidos
    if (subassuntos.length > 0) {
      whereConditions.push(`q.subassunto IN (${subassuntos.map(() => '?').join(',')})`);
      params.push(...subassuntos);
    }

    // Filtrar por tipo se fornecido
    if (tipo) {
      whereConditions.push('q.tipo = ?');
      params.push(tipo);
    }

    // Usar LEFT JOIN para excluir questões já respondidas (mais eficiente que NOT IN)
    const query = `
      SELECT q.* 
      FROM questions q
      LEFT JOIN user_question_practice uqp ON q.id = uqp.question_id AND uqp.user_id = ?
      WHERE ${whereConditions.join(' AND ')} 
        AND uqp.question_id IS NULL
      ORDER BY RAND()
      LIMIT 1
    `;

    const [rows] = await db.execute(query, [userId, ...params]);
    if (rows.length === 0) return null;

    const question = rows[0];
    if (question.alternativas) {
      try {
        question.alternativas = JSON.parse(question.alternativas);
      } catch (e) {
        question.alternativas = [];
      }
    }

    return question;
  }

  // Modo Prática - Registrar resposta
  async savePracticeAnswer(userId, questionId, answerGiven, correct, timeSpentSeconds) {
    await db.execute(
      `INSERT INTO user_question_practice 
       (user_id, question_id, answer_given, correct, time_spent_seconds)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
       answer_given = VALUES(answer_given),
       correct = VALUES(correct),
       time_spent_seconds = VALUES(time_spent_seconds),
       updated_at = CURRENT_TIMESTAMP`,
      [userId, questionId, answerGiven, correct, timeSpentSeconds]
    );
    return true;
  }

  // Modo Prática - Buscar histórico
  async findPracticeHistory(userId, { page = 1, perPage = 20, assunto }) {
    const offset = (page - 1) * perPage;
    let whereConditions = ['p.user_id = ?'];
    let params = [userId];

    if (assunto) {
      whereConditions.push('q.assunto = ?');
      params.push(assunto);
    }

    const query = `
      SELECT 
        p.*,
        q.pergunta,
        q.assunto,
        q.subassunto,
        q.tipo,
        q.resposta_correta,
        q.explicacao,
        q.alternativas
      FROM user_question_practice p
      JOIN questions q ON p.question_id = q.id
      WHERE ${whereConditions.join(' AND ')}
      ORDER BY p.created_at DESC
      LIMIT ? OFFSET ?
    `;

    params.push(perPage, offset);
    const [rows] = await db.execute(query, params);

    // Parse alternativas
    for (const row of rows) {
      if (row.alternativas) {
        try {
          row.alternativas = JSON.parse(row.alternativas);
        } catch (e) {
          row.alternativas = [];
        }
      }
    }

    const countQuery = `
      SELECT COUNT(*) as total
      FROM user_question_practice p
      JOIN questions q ON p.question_id = q.id
      WHERE ${whereConditions.join(' AND ')}
    `;
    const [countRows] = await db.execute(countQuery, params.slice(0, -2));
    const total = countRows[0]?.total || 0;

    return { data: rows, total, page, perPage };
  }

  // Modo Prática - Resetar questão
  async resetPracticeAnswer(userId, questionId) {
    await db.execute(
      'DELETE FROM user_question_practice WHERE user_id = ? AND question_id = ?',
      [userId, questionId]
    );
    return true;
  }

  // Admin - Listar questões pendentes
  async findPendingApproval({ page = 1, perPage = 20, assunto, subassunto, tipo }) {
    const offset = (page - 1) * perPage;
    // Para admin, mostra questão COMPLETA (sem truncar)
    const whereConditions = ['(aprovada = FALSE OR (gerada_por_ia = TRUE AND aprovada IS NULL))'];
    const params = [];

    if (assunto) {
      whereConditions.push('assunto = ?');
      params.push(assunto);
    }

    if (subassunto) {
      whereConditions.push('subassunto = ?');
      params.push(subassunto);
    }

    if (tipo) {
      whereConditions.push('tipo = ?');
      params.push(tipo);
    }

    const whereClause = whereConditions.join(' AND ');
    
    const query = `
      SELECT 
        id,
        pergunta, -- Questão completa, sem truncar
        assunto,
        subassunto,
        tipo,
        resposta_correta,
        aprovada,
        gerada_por_ia,
        created_at,
        alternativas, -- Alternativas completas, sem truncar
        explicacao, -- Explicação completa, sem truncar
        origem
      FROM questions
      WHERE ${whereClause}
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    `;
    const [rows] = await db.execute(query, [...params, perPage, offset]);

    for (const row of rows) {
      if (row.alternativas && typeof row.alternativas === 'string') {
        try {
          // Tentar parsear apenas se não foi truncado
          if (!row.alternativas.endsWith('...')) {
            row.alternativas = JSON.parse(row.alternativas);
          } else {
            // Se foi truncado, marcar como truncado e manter como string
            // O frontend vai lidar com isso
            row.alternativas_truncated = true;
          }
        } catch (e) {
          // Se não for JSON válido, manter como string
          console.warn('Erro ao parsear alternativas (ID: ' + row.id + '):', e.message);
        }
      }
    }

    // Conta total com os mesmos filtros
    const countQuery = `SELECT COUNT(*) as total FROM questions WHERE ${whereClause}`;
    const [countRows] = await db.execute(countQuery, params);
    const total = countRows[0]?.total || 0;

    return { data: rows, total, page, perPage };
  }

  // Admin - Aprovar questão
  async approveQuestion(questionId, approvedBy) {
    await db.execute(
      `UPDATE questions SET 
       aprovada = TRUE,
       aprovada_por = ?,
       aprovada_em = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [approvedBy, questionId]
    );
    return true;
  }

  // Admin - Rejeitar questão
  async rejectQuestion(questionId, approvedBy) {
    await db.execute(
      `UPDATE questions SET 
       aprovada = FALSE,
       aprovada_por = ?,
       aprovada_em = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [approvedBy, questionId]
    );
    return true;
  }
}

module.exports = new QuestionsRepository();


