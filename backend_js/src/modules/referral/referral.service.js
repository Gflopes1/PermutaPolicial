const ApiError = require('../../core/utils/ApiError');
const analyticsService = require('../analytics/analytics.service');
const referralRepository = require('./referral.repository');
const {
  generateReferralCode,
  computeTier,
  getNextLevelProgress,
  buildReferralLink,
} = require('./referral.utils');

class ReferralService {
  async ensureReferralCode(userId) {
    const existing = await referralRepository.findCodeByUserId(userId);
    if (existing) return existing;

    const user = await referralRepository.getUserName(userId);
    if (!user) throw new ApiError(404, 'Usuário não encontrado.');

    let attempts = 0;
    while (attempts < 25) {
      const code = generateReferralCode(user.nome);
      const exists = await referralRepository.codeExists(code);
      if (!exists) {
        await referralRepository.createCode(userId, code);
        return referralRepository.findCodeByUserId(userId);
      }
      attempts += 1;
    }
    throw new ApiError(500, 'Não foi possível gerar código de indicação.');
  }

  async validateCode(code) {
    const row = await referralRepository.findCodeByCode(code);
    if (!row) {
      return { valid: false };
    }
    return {
      valid: true,
      referrer_public_name: row.qso || row.nome?.split(' ')[0] || 'Policial',
      forca_sigla: row.forca_sigla || null,
    };
  }

  async registerClick(code, metadata = {}) {
    const validation = await this.validateCode(code);
    await analyticsService.registrarEvento({
      usuario_id: metadata.usuario_id || null,
      evento_tipo: 'referral_link_clicked',
      metadata: { code: String(code).trim().toUpperCase(), ...metadata },
      ip_address: metadata.ip_address || null,
      user_agent: metadata.user_agent || null,
    });
    return validation;
  }

  async getMyReferral(userId) {
    const codeRow = await this.ensureReferralCode(userId);
    const counts = await referralRepository.countByReferrer(userId);
    const verifiedCount = Number(counts.verified) || 0;
    const tier = computeTier(verifiedCount);
    const progress = getNextLevelProgress(verifiedCount);
    const referrals = await referralRepository.listReferralsByReferrer(userId, 10);

    return {
      code: codeRow.code,
      link: buildReferralLink(codeRow.code),
      total: Number(counts.total) || 0,
      verified_count: verifiedCount,
      pending_count: Number(counts.pending) || 0,
      tier: tier.tier,
      tier_label: tier.label,
      next_level: progress.next_threshold,
      remaining_to_next: progress.remaining,
      progress_to_next: progress.progress,
      referrals: referrals.map((r) => ({
        status: r.status,
        created_at: r.created_at,
        verified_at: r.verified_at,
        public_name: r.qso || r.nome?.split(' ')[0],
        forca_sigla: r.forca_sigla,
      })),
    };
  }

  /**
   * Cria indicação no cadastro. Nunca aceita referrer_user_id do client.
   * @param {number} referredUserId
   * @param {string|null} referralCode
   * @param {{ alreadyVerified?: boolean, connection?: object }} options
   */
  async createReferralOnSignup(referredUserId, referralCode, options = {}) {
    if (!referralCode || !String(referralCode).trim()) {
      return { created: false, reason: 'no_code' };
    }

    const codeRow = await referralRepository.findCodeByCode(referralCode);
    if (!codeRow) {
      return { created: false, reason: 'invalid_code' };
    }

    if (codeRow.user_id === referredUserId) {
      return { created: false, reason: 'self_referral' };
    }

    const existing = await referralRepository.findReferralByReferredUserId(referredUserId);
    if (existing) {
      return { created: false, reason: 'already_referred' };
    }

    const status = options.alreadyVerified ? 'verified' : 'pending';

    await referralRepository.createReferral({
      referrerUserId: codeRow.user_id,
      referredUserId,
      referralCode: codeRow.code,
      status,
    });

    analyticsService.registrarEvento({
      usuario_id: referredUserId,
      evento_tipo: 'referral_signup_completed',
      metadata: {
        referral_code: codeRow.code,
        referrer_user_id: codeRow.user_id,
        status,
      },
    }).catch(() => {});

    if (status === 'verified') {
      await this._emitVerifiedEvent(referredUserId, codeRow.user_id);
    }

    return { created: true, status, referrer_user_id: codeRow.user_id };
  }

  async markVerified(referredUserId) {
    const affected = await referralRepository.markReferralVerified(referredUserId);
    if (affected > 0) {
      const referral = await referralRepository.findReferralByReferredUserId(referredUserId);
      if (referral) {
        await this._emitVerifiedEvent(referredUserId, referral.referrer_user_id);
      }
    }
    return { updated: affected > 0 };
  }

  /**
   * Garante indicação pending/verified após confirmação de e-mail.
   * Recupera código do body ou de evento gravado no cadastro.
   */
  async ensureReferralAfterEmailConfirm(referredUserId, referralCodeFromBody) {
    const existing = await referralRepository.findReferralByReferredUserId(referredUserId);
    if (!existing) {
      let code = referralCodeFromBody ? String(referralCodeFromBody).trim() : '';
      if (!code) {
        code = await referralRepository.findReferralCodeFromSignupEvent(referredUserId);
      }
      if (code) {
        await this.createReferralOnSignup(referredUserId, code, { alreadyVerified: false });
      }
    }
    return this.markVerified(referredUserId);
  }

  async _emitVerifiedEvent(referredUserId, referrerUserId) {
    await analyticsService.registrarEvento({
      usuario_id: referrerUserId,
      evento_tipo: 'referral_verified',
      metadata: { referred_user_id: referredUserId },
    }).catch(() => {});
  }

  /**
   * Usuário logado abrindo link de indicação.
   */
  async attachReferralToLoggedInUser(userId, referralCode) {
    if (!referralCode) return { attached: false, reason: 'no_code' };

    const codeRow = await referralRepository.findCodeByCode(referralCode);
    if (!codeRow) return { attached: false, reason: 'invalid_code' };
    if (codeRow.user_id === userId) return { attached: false, reason: 'own_code' };

    const existing = await referralRepository.findReferralByReferredUserId(userId);
    if (existing) return { attached: false, reason: 'already_referred' };

    const user = await referralRepository.getUserName(userId);
    const alreadyVerified = user?.status_verificacao === 'VERIFICADO';

    const result = await this.createReferralOnSignup(userId, referralCode, { alreadyVerified });
    return { attached: result.created, ...result };
  }

  async getRanking(userId, { scope = 'forca', forcaId, estadoId, page = 1, limit = 20 }) {
    const offset = (page - 1) * limit;
    let resolvedForcaId = forcaId;
    let resolvedEstadoId = estadoId;

    if (scope === 'forca' && !resolvedForcaId && userId) {
      const [rows] = await require('../../config/db').execute(
        'SELECT forca_id FROM policiais WHERE id = ?',
        [userId]
      );
      resolvedForcaId = rows[0]?.forca_id;
    }

    const rows = await referralRepository.getRanking({
      scope,
      forcaId: resolvedForcaId,
      estadoId: resolvedEstadoId,
      limit,
      offset,
    });

    return rows.map((r, index) => ({
      rank: offset + index + 1,
      public_name: r.qso || r.nome?.split(' ')[0],
      forca_sigla: r.forca_sigla,
      estado_sigla: r.estado_sigla,
      verified_count: Number(r.verified_count) || 0,
    }));
  }

  async dismissCampaign(userId, campaignId) {
    if (!campaignId) throw new ApiError(400, 'campaign_id é obrigatório.');
    await referralRepository.dismissCampaign(userId, campaignId);
    return { success: true };
  }

  async getActiveCampaign(userId) {
    const campaign = await referralRepository.getActiveCampaignConfig();
    if (!campaign) return null;

    if (userId) {
      const dismissed = await referralRepository.isCampaignDismissed(userId, campaign.id);
      if (dismissed) return null;
    }

    return campaign;
  }

  async trackShare(userId, metadata = {}) {
    await analyticsService.registrarEvento({
      usuario_id: userId,
      evento_tipo: 'referral_share_clicked',
      metadata,
    });
    return { success: true };
  }

  async trackSignupStarted(metadata = {}) {
    await analyticsService.registrarEvento({
      usuario_id: metadata.usuario_id || null,
      evento_tipo: 'referral_signup_started',
      metadata,
    });
    return { success: true };
  }

  // --- Admin ---

  async getAdminStats() {
    return referralRepository.getAdminStats();
  }

  async getAdminRanking(query) {
    const rows = await referralRepository.getRanking({
      scope: query.scope || 'geral',
      forcaId: query.forca_id ? parseInt(query.forca_id, 10) : null,
      estadoId: query.estado_id ? parseInt(query.estado_id, 10) : null,
      limit: Math.min(parseInt(query.limit, 10) || 50, 100),
      offset: parseInt(query.offset, 10) || 0,
    });
    return rows.map((r, index) => ({
      rank: (parseInt(query.offset, 10) || 0) + index + 1,
      public_name: r.qso || r.nome?.split(' ')[0],
      forca_sigla: r.forca_sigla,
      estado_sigla: r.estado_sigla,
      verified_count: Number(r.verified_count) || 0,
    }));
  }

  async getAdminUserDetail(userId) {
    return referralRepository.getUserReferralDetail(userId);
  }

  async getForceGoals() {
    return referralRepository.getForceGoals();
  }

  async getAdminCampaign() {
    const campaign = await referralRepository.getCampaignConfigRaw();
    return campaign || null;
  }

  async saveAdminCampaign(payload) {
    const id = String(payload.id || '').trim();
    if (!id) throw new ApiError(400, 'ID da campanha é obrigatório.');

    const campaign = {
      id,
      title: String(payload.title || '').trim(),
      description: String(payload.description || '').trim(),
      primary_action: payload.primary_action === 'close' ? 'close' : 'referral',
      primary_label: String(payload.primary_label || 'Convidar colegas').trim(),
      secondary_label: payload.secondary_label
        ? String(payload.secondary_label).trim()
        : 'Agora não',
      show_share: payload.show_share !== false,
      active: payload.active !== false,
    };

    if (!campaign.title) throw new ApiError(400, 'Título é obrigatório.');
    if (!campaign.description) throw new ApiError(400, 'Descrição é obrigatória.');

    await referralRepository.upsertCampaignConfig(campaign);
    return campaign;
  }

  async updateForceGoal(forcaId, metaUsuarios, ativo) {
    await referralRepository.upsertForceGoal(forcaId, metaUsuarios, ativo);
    return { success: true };
  }

  async markAgentVerified(referredUserId) {
    await analyticsService.registrarEvento({
      usuario_id: referredUserId,
      evento_tipo: 'referral_agent_verified',
      metadata: { referred_user_id: referredUserId },
    }).catch(() => {});
  }

  async trackIntentionCreated(referredUserId, referrerUserId) {
    await analyticsService.registrarEvento({
      usuario_id: referrerUserId,
      evento_tipo: 'referred_user_intention_created',
      metadata: { referred_user_id: referredUserId },
    }).catch(() => {});
  }
}

module.exports = new ReferralService();
