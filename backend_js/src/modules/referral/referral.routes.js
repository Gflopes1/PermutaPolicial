const express = require('express');
const { celebrate } = require('celebrate');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const optionalAuthMiddleware = require('../../core/middlewares/optionalAuth.middleware');
const adminMiddleware = require('../../core/middlewares/admin.middleware');
const referralValidation = require('./referral.validation');
const referralController = require('./referral.controller');

const router = express.Router();

// Público
router.get(
  '/validate/:code',
  celebrate(referralValidation.validateCode),
  referralController.validateCode
);

router.post(
  '/click',
  optionalAuthMiddleware,
  celebrate(referralValidation.registerClick),
  referralController.registerClick
);

router.get(
  '/campaign/active',
  optionalAuthMiddleware,
  referralController.getActiveCampaign
);

// Autenticado
router.get('/me', authMiddleware, referralController.getMyReferral);

router.get(
  '/ranking',
  authMiddleware,
  celebrate(referralValidation.ranking),
  referralController.getRanking
);

router.post(
  '/dismiss-campaign',
  authMiddleware,
  celebrate(referralValidation.dismissCampaign),
  referralController.dismissCampaign
);

router.post('/track-share', authMiddleware, referralController.trackShare);

router.post(
  '/attach',
  authMiddleware,
  celebrate(referralValidation.attachReferral),
  referralController.attachReferral
);

// Admin
router.get('/admin/stats', authMiddleware, adminMiddleware, referralController.getAdminStats);

router.get(
  '/admin/ranking',
  authMiddleware,
  adminMiddleware,
  celebrate(referralValidation.adminRanking),
  referralController.getAdminRanking
);

router.get(
  '/admin/users/:id',
  authMiddleware,
  adminMiddleware,
  celebrate(referralValidation.adminUserId),
  referralController.getAdminUserDetail
);

router.get('/admin/force-goals', authMiddleware, adminMiddleware, referralController.getForceGoals);

router.put(
  '/admin/force-goals/:forcaId',
  authMiddleware,
  adminMiddleware,
  celebrate(referralValidation.updateForceGoal),
  referralController.updateForceGoal
);

router.get(
  '/admin/campaign',
  authMiddleware,
  adminMiddleware,
  referralController.getAdminCampaign
);

router.put(
  '/admin/campaign',
  authMiddleware,
  adminMiddleware,
  celebrate(referralValidation.adminCampaign),
  referralController.saveAdminCampaign
);

module.exports = router;
