const referralService = require('./referral.service');

const handle = (fn, status = 200) => async (req, res, next) => {
  try {
    const data = await fn(req);
    res.status(status).json({ status: 'success', data });
  } catch (e) {
    next(e);
  }
};

module.exports = {
  validateCode: handle((req) =>
    referralService.validateCode(req.params.code)
  ),

  registerClick: handle((req) =>
    referralService.registerClick(req.body.code, {
      ip_address: req.ip,
      user_agent: req.get('user-agent'),
      usuario_id: req.user?.id || null,
    })
  ),

  getMyReferral: handle((req) =>
    referralService.getMyReferral(req.user.id)
  ),

  getRanking: handle((req) =>
    referralService.getRanking(req.user.id, {
      scope: req.query.scope,
      forcaId: req.query.forca_id,
      estadoId: req.query.estado_id,
      page: req.query.page,
      limit: req.query.limit,
    })
  ),

  dismissCampaign: handle((req) =>
    referralService.dismissCampaign(req.user.id, req.body.campaign_id)
  ),

  getActiveCampaign: handle((req) =>
    referralService.getActiveCampaign(req.user?.id || null)
  ),

  trackShare: handle((req) =>
    referralService.trackShare(req.user.id, req.body || {})
  ),

  attachReferral: handle((req) =>
    referralService.attachReferralToLoggedInUser(req.user.id, req.body.referral_code)
  ),

  getAdminStats: handle(() => referralService.getAdminStats()),

  getAdminRanking: handle((req) => referralService.getAdminRanking(req.query)),

  getAdminUserDetail: handle((req) =>
    referralService.getAdminUserDetail(parseInt(req.params.id, 10))
  ),

  getForceGoals: handle(() => referralService.getForceGoals()),

  updateForceGoal: handle((req) =>
    referralService.updateForceGoal(
      parseInt(req.params.forcaId, 10),
      req.body.meta_usuarios,
      req.body.ativo
    )
  ),

  getAdminCampaign: handle(() => referralService.getAdminCampaign()),

  saveAdminCampaign: handle((req) => referralService.saveAdminCampaign(req.body)),
};
