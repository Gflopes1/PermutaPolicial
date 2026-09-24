const db = require('../../config/db');

class PushRepository {
  async upsertToken(policialId, token, platform = 'android') {
    await db.execute(
      `INSERT INTO device_tokens (policial_id, token, platform)
       VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE policial_id = VALUES(policial_id), platform = VALUES(platform), atualizado_em = CURRENT_TIMESTAMP`,
      [policialId, token, platform]
    );
  }

  async deleteToken(policialId, token) {
    const [result] = await db.execute(
      'DELETE FROM device_tokens WHERE policial_id = ? AND token = ?',
      [policialId, token]
    );
    return result.affectedRows > 0;
  }

  async deleteTokenByValue(token) {
    const [result] = await db.execute('DELETE FROM device_tokens WHERE token = ?', [token]);
    return result.affectedRows > 0;
  }

  async findTokensByPolicialId(policialId) {
    const [rows] = await db.execute(
      'SELECT token, platform FROM device_tokens WHERE policial_id = ?',
      [policialId]
    );
    return rows;
  }
}

module.exports = new PushRepository();
