const db = require('../../config/db');

class ReferralRepository {
  async findCodeByUserId(userId) {
    const [rows] = await db.execute(
      'SELECT id, user_id, code, created_at FROM referral_codes WHERE user_id = ?',
      [userId]
    );
    return rows[0] || null;
  }

  async findCodeByCode(code) {
    const normalized = String(code || '').trim().toUpperCase();
    const [rows] = await db.execute(
      `SELECT rc.id, rc.user_id, rc.code, p.nome, p.qso, fp.sigla AS forca_sigla
       FROM referral_codes rc
       JOIN policiais p ON p.id = rc.user_id
       LEFT JOIN forcas_policiais fp ON fp.id = p.forca_id
       WHERE rc.code = ?`,
      [normalized]
    );
    return rows[0] || null;
  }

  async codeExists(code) {
    const [rows] = await db.execute(
      'SELECT id FROM referral_codes WHERE code = ? LIMIT 1',
      [String(code).trim().toUpperCase()]
    );
    return rows.length > 0;
  }

  async createCode(userId, code) {
    const [result] = await db.execute(
      'INSERT INTO referral_codes (user_id, code) VALUES (?, ?)',
      [userId, String(code).trim().toUpperCase()]
    );
    return result.insertId;
  }

  async findReferralByReferredUserId(referredUserId) {
    const [rows] = await db.execute(
      'SELECT * FROM referrals WHERE referred_user_id = ?',
      [referredUserId]
    );
    return rows[0] || null;
  }

  async findReferralCodeFromSignupEvent(referredUserId) {
    const [rows] = await db.execute(
      `SELECT metadata FROM user_events
       WHERE usuario_id = ? AND evento_tipo = 'referral_signup_started'
       ORDER BY id DESC LIMIT 1`,
      [referredUserId]
    );
    const raw = rows[0]?.metadata;
    if (!raw) return null;
    try {
      const meta = typeof raw === 'string' ? JSON.parse(raw) : raw;
      const code = meta?.referral_code;
      return code ? String(code).trim().toUpperCase() : null;
    } catch (_) {
      return null;
    }
  }

  async createReferral({ referrerUserId, referredUserId, referralCode, status }) {
    const [result] = await db.execute(
      `INSERT INTO referrals (referrer_user_id, referred_user_id, referral_code, status, verified_at)
       VALUES (?, ?, ?, ?, ?)`,
      [
        referrerUserId,
        referredUserId,
        String(referralCode).trim().toUpperCase(),
        status,
        status === 'verified' ? new Date() : null,
      ]
    );
    return result.insertId;
  }

  async markReferralVerified(referredUserId) {
    const [result] = await db.execute(
      `UPDATE referrals
       SET status = 'verified', verified_at = COALESCE(verified_at, NOW())
       WHERE referred_user_id = ? AND status = 'pending'`,
      [referredUserId]
    );
    return result.affectedRows;
  }

  async countByReferrer(referrerUserId) {
    const [rows] = await db.execute(
      `SELECT
         COUNT(*) AS total,
         SUM(CASE WHEN status = 'verified' THEN 1 ELSE 0 END) AS verified,
         SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) AS pending
       FROM referrals WHERE referrer_user_id = ?`,
      [referrerUserId]
    );
    return rows[0] || { total: 0, verified: 0, pending: 0 };
  }

  async listReferralsByReferrer(referrerUserId, limit = 20) {
    const [rows] = await db.execute(
      `SELECT r.id, r.status, r.created_at, r.verified_at, r.referral_code,
              p.qso, p.nome, fp.sigla AS forca_sigla
       FROM referrals r
       JOIN policiais p ON p.id = r.referred_user_id
       LEFT JOIN forcas_policiais fp ON fp.id = p.forca_id
       WHERE r.referrer_user_id = ?
       ORDER BY r.created_at DESC
       LIMIT ?`,
      [referrerUserId, limit]
    );
    return rows;
  }

  async dismissCampaign(userId, campaignId) {
    await db.execute(
      `INSERT INTO referral_campaign_dismissals (user_id, campaign_id)
       VALUES (?, ?)
       ON DUPLICATE KEY UPDATE dismissed_at = CURRENT_TIMESTAMP`,
      [userId, campaignId]
    );
  }

  async isCampaignDismissed(userId, campaignId) {
    const [rows] = await db.execute(
      'SELECT id FROM referral_campaign_dismissals WHERE user_id = ? AND campaign_id = ?',
      [userId, campaignId]
    );
    return rows.length > 0;
  }

  async getActiveCampaignConfig() {
    const campaign = await this.getCampaignConfigRaw();
    if (!campaign || campaign.active === false) return null;
    return campaign;
  }

  async getCampaignConfigRaw() {
    const [rows] = await db.execute(
      "SELECT valor FROM configuracoes_gerais WHERE chave = 'referral_campaign_active'"
    );
    if (rows.length === 0 || !rows[0].valor) return null;
    try {
      return JSON.parse(rows[0].valor);
    } catch {
      return null;
    }
  }

  async upsertCampaignConfig(campaign) {
    const json = JSON.stringify(campaign);
    await db.execute(
      `INSERT INTO configuracoes_gerais (chave, valor) VALUES ('referral_campaign_active', ?)
       ON DUPLICATE KEY UPDATE valor = ?`,
      [json, json]
    );
    return campaign;
  }

  async getRanking({ scope = 'geral', forcaId, estadoId, limit = 50, offset = 0 }) {
    let whereExtra = '';
    const params = [];

    if (scope === 'forca' && forcaId) {
      whereExtra = ' AND p.forca_id = ?';
      params.push(forcaId);
    } else if (scope === 'estado' && estadoId) {
      whereExtra = ` AND COALESCE(m_direto.estado_id, m_unidade.estado_id) = ?`;
      params.push(estadoId);
    }

    params.push(limit, offset);

    const [rows] = await db.execute(
      `SELECT p.id, p.qso, p.nome, fp.sigla AS forca_sigla,
              e.sigla AS estado_sigla,
              COUNT(CASE WHEN r.status = 'verified' THEN 1 END) AS verified_count
       FROM referrals r
       JOIN policiais p ON p.id = r.referrer_user_id
       LEFT JOIN forcas_policiais fp ON fp.id = p.forca_id
       LEFT JOIN municipios m_direto ON m_direto.id = p.municipio_atual_id
       LEFT JOIN unidades u ON u.id = p.unidade_atual_id
       LEFT JOIN municipios m_unidade ON m_unidade.id = u.municipio_id
       LEFT JOIN estados e ON e.id = COALESCE(m_direto.estado_id, m_unidade.estado_id)
       WHERE r.status = 'verified' ${whereExtra}
       GROUP BY p.id, p.qso, p.nome, fp.sigla, e.sigla
       ORDER BY verified_count DESC, p.qso ASC
       LIMIT ? OFFSET ?`,
      params
    );
    return rows;
  }

  async getAdminStats() {
    const [totals] = await db.execute(
      `SELECT
         COUNT(*) AS total_referrals,
         SUM(CASE WHEN status = 'verified' THEN 1 ELSE 0 END) AS verified,
         SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) AS pending,
         SUM(CASE WHEN status = 'invalid' THEN 1 ELSE 0 END) AS invalid
       FROM referrals`
    );

    const [clicks] = await db.execute(
      `SELECT COUNT(*) AS clicks FROM user_events WHERE evento_tipo = 'referral_link_clicked'`
    );

    const [signups] = await db.execute(
      `SELECT COUNT(*) AS signups FROM user_events WHERE evento_tipo = 'referral_signup_completed'`
    );

    return {
      ...totals[0],
      clicks: clicks[0]?.clicks || 0,
      signups: signups[0]?.signups || 0,
    };
  }

  async getUserReferralDetail(userId) {
    const code = await this.findCodeByUserId(userId);
    const counts = await this.countByReferrer(userId);
    const referrals = await this.listReferralsByReferrer(userId, 100);
    return { code, counts, referrals };
  }

  async getForceGoals() {
    const [rows] = await db.execute(
      `SELECT fg.id, fg.forca_id, fg.meta_usuarios, fg.ativo, fp.sigla, fp.nome,
              (SELECT COUNT(*) FROM policiais p WHERE p.forca_id = fg.forca_id AND p.status_verificacao = 'VERIFICADO') AS usuarios_atuais
       FROM referral_force_goals fg
       JOIN forcas_policiais fp ON fp.id = fg.forca_id
       WHERE fg.ativo = 1
       ORDER BY fp.sigla`
    );
    return rows;
  }

  async upsertForceGoal(forcaId, metaUsuarios, ativo = 1) {
    await db.execute(
      `INSERT INTO referral_force_goals (forca_id, meta_usuarios, ativo)
       VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE meta_usuarios = VALUES(meta_usuarios), ativo = VALUES(ativo)`,
      [forcaId, metaUsuarios, ativo ? 1 : 0]
    );
  }

  async getUserName(userId) {
    const [rows] = await db.execute(
      'SELECT id, nome, qso, status_verificacao FROM policiais WHERE id = ?',
      [userId]
    );
    return rows[0] || null;
  }
}

module.exports = new ReferralRepository();
