const db = require('../../config/db');

class CommentsRepository {
  async findByQuestionId(questionId, { page = 1, perPage = 20, sort = 'newest' }) {
    const offset = (page - 1) * perPage;
    const orderBy = sort === 'oldest' ? 'ASC' : 'DESC';

    const [rows] = await db.execute(
      `SELECT 
        c.*,
        p.nome as user_nome,
        NULL as user_foto,
        (SELECT COUNT(*) FROM comment_likes WHERE comment_id = c.id) as likes_count,
        (SELECT COUNT(*) FROM question_comments WHERE parent_id = c.id AND deleted_at IS NULL) as replies_count
       FROM question_comments c
       JOIN policiais p ON c.user_id = p.id
       WHERE c.question_id = ? AND c.parent_id IS NULL AND c.deleted_at IS NULL AND c.is_hidden = FALSE
       ORDER BY c.created_at ${orderBy}
       LIMIT ? OFFSET ?`,
      [questionId, perPage, offset]
    );

    const [countRows] = await db.execute(
      `SELECT COUNT(*) as total
       FROM question_comments
       WHERE question_id = ? AND parent_id IS NULL AND deleted_at IS NULL AND is_hidden = FALSE`,
      [questionId]
    );

    const total = countRows[0]?.total || 0;

    for (const comment of rows) {
      const [replies] = await db.execute(
        `SELECT 
          c.*,
          p.nome as user_nome,
          NULL as user_foto,
          (SELECT COUNT(*) FROM comment_likes WHERE comment_id = c.id) as likes_count
         FROM question_comments c
         JOIN policiais p ON c.user_id = p.id
         WHERE c.parent_id = ? AND c.deleted_at IS NULL AND c.is_hidden = FALSE
         ORDER BY c.created_at ASC
         LIMIT 2`,
        [comment.id]
      );
      comment.replies = replies;
    }

    return { data: rows, total, page, perPage };
  }

  async findReplies(parentId, { page = 1, perPage = 10 }) {
    const offset = (page - 1) * perPage;

    const [rows] = await db.execute(
      `SELECT 
        c.*,
        p.nome as user_nome,
        NULL as user_foto,
        (SELECT COUNT(*) FROM comment_likes WHERE comment_id = c.id) as likes_count
       FROM question_comments c
       JOIN policiais p ON c.user_id = p.id
       WHERE c.parent_id = ? AND c.deleted_at IS NULL AND c.is_hidden = FALSE
       ORDER BY c.created_at ASC
       LIMIT ? OFFSET ?`,
      [parentId, perPage, offset]
    );

    return rows;
  }

  async create(questionId, userId, content, parentId = null) {
    const [result] = await db.execute(
      `INSERT INTO question_comments (question_id, user_id, parent_id, content)
       VALUES (?, ?, ?, ?)`,
      [questionId, userId, parentId, content]
    );

    return result.insertId;
  }

  async findById(id) {
    const [rows] = await db.execute(
      'SELECT * FROM question_comments WHERE id = ?',
      [id]
    );
    return rows[0] || null;
  }

  async update(id, content) {
    await db.execute(
      'UPDATE question_comments SET content = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [content, id]
    );
    return true;
  }

  async delete(id) {
    await db.execute(
      'UPDATE question_comments SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
      [id]
    );
    return true;
  }

  async toggleLike(commentId, userId) {
    const connection = await db.getConnection();
    try {
      await connection.beginTransaction();

      const [existing] = await connection.execute(
        'SELECT id FROM comment_likes WHERE comment_id = ? AND user_id = ?',
        [commentId, userId]
      );

      if (existing.length > 0) {
        await connection.execute(
          'DELETE FROM comment_likes WHERE comment_id = ? AND user_id = ?',
          [commentId, userId]
        );
        await connection.commit();
        return { liked: false };
      } else {
        await connection.execute(
          'INSERT INTO comment_likes (comment_id, user_id) VALUES (?, ?)',
          [commentId, userId]
        );
        await connection.commit();
        return { liked: true };
      }
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async report(commentId, userId, reason, note) {
    await db.execute(
      `INSERT INTO comment_reports (comment_id, user_id, reason, note)
       VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE reason = VALUES(reason), note = VALUES(note)`,
      [commentId, userId, reason, note]
    );
    return true;
  }

  async getReportsCount(commentId) {
    const [rows] = await db.execute(
      'SELECT COUNT(*) as count FROM comment_reports WHERE comment_id = ?',
      [commentId]
    );
    return rows[0]?.count || 0;
  }

  async hide(commentId) {
    await db.execute(
      'UPDATE question_comments SET is_hidden = TRUE WHERE id = ?',
      [commentId]
    );
    return true;
  }

  async unhide(commentId) {
    await db.execute(
      'UPDATE question_comments SET is_hidden = FALSE WHERE id = ?',
      [commentId]
    );
    return true;
  }

  async logModeration(commentId, moderatorId, action, note) {
    await db.execute(
      `INSERT INTO comment_moderation_logs (comment_id, moderator_id, action, note)
       VALUES (?, ?, ?, ?)`,
      [commentId, moderatorId, action, note]
    );
    return true;
  }

  async getRecentCommentsByUser(userId, minutes = 1) {
    const [rows] = await db.execute(
      `SELECT COUNT(*) as count
       FROM question_comments
       WHERE user_id = ? AND created_at > DATE_SUB(NOW(), INTERVAL ? MINUTE)`,
      [userId, minutes]
    );
    return rows[0]?.count || 0;
  }
}

module.exports = new CommentsRepository();


