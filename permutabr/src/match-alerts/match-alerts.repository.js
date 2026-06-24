const db = require('../../config/db');

class MatchAlertsRepository {
  async isAlertasAtivo(policialId) {
    const [rows] = await db.execute(
      'SELECT COALESCE(alertas_match_ativo, 1) as ativo FROM policiais WHERE id = ?',
      [policialId]
    );
    return rows[0]?.ativo === 1;
  }

  async wasAlreadyNotified(usuarioId, matchChave) {
    const [rows] = await db.execute(
      'SELECT id FROM match_alertas_log WHERE usuario_id = ? AND match_chave = ? LIMIT 1',
      [usuarioId, matchChave]
    );
    return rows.length > 0;
  }

  async registerNotification(usuarioId, matchChave, tipoMatch) {
    await db.execute(
      `INSERT IGNORE INTO match_alertas_log (usuario_id, match_chave, tipo_match)
       VALUES (?, ?, ?)`,
      [usuarioId, matchChave, tipoMatch]
    );
  }

  async countAlertasEnviados(dataInicio, dataFim) {
    let where = '';
    const params = [];
    if (dataInicio && dataFim) {
      where = 'WHERE criado_em BETWEEN ? AND ?';
      params.push(dataInicio, dataFim);
    } else if (dataInicio) {
      where = 'WHERE criado_em >= ?';
      params.push(dataInicio);
    }
    const [rows] = await db.execute(
      `SELECT COUNT(*) as total FROM match_alertas_log ${where}`,
      params
    );
    return rows[0]?.total || 0;
  }

  async countAlertasPorTipo(dataInicio, dataFim) {
    let where = '';
    const params = [];
    if (dataInicio && dataFim) {
      where = 'WHERE criado_em BETWEEN ? AND ?';
      params.push(dataInicio, dataFim);
    } else if (dataInicio) {
      where = 'WHERE criado_em >= ?';
      params.push(dataInicio);
    }
    const [rows] = await db.execute(
      `SELECT tipo_match, COUNT(*) as total
       FROM match_alertas_log ${where}
       GROUP BY tipo_match`,
      params
    );
    return rows;
  }

  async findUsuariosParaVarredura(limit = 100) {
    const [rows] = await db.execute(
      `SELECT DISTINCT p.id
       FROM policiais p
       INNER JOIN intencoes i ON i.policial_id = p.id
       WHERE p.status_verificacao = 'VERIFICADO'
         AND COALESCE(p.alertas_match_ativo, 1) = 1
         AND (i.unidade_atual_id IS NOT NULL OR i.municipio_atual_id IS NOT NULL
              OR p.unidade_atual_id IS NOT NULL OR p.municipio_atual_id IS NOT NULL)
       ORDER BY p.id ASC
       LIMIT ?`,
      [limit]
    );
    return rows.map((r) => r.id);
  }
}

module.exports = new MatchAlertsRepository();
