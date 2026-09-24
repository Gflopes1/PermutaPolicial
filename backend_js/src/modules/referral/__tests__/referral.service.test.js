const referralService = require('../referral.service');
const referralRepository = require('../referral.repository');
const analyticsService = require('../../analytics/analytics.service');

jest.mock('../referral.repository');
jest.mock('../../analytics/analytics.service');

describe('ReferralService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    analyticsService.registrarEvento = jest.fn().mockResolvedValue({ success: true });
  });

  describe('createReferralOnSignup', () => {
    it('caso 1: cria referral pending quando email ainda não verificado', async () => {
      referralRepository.findCodeByCode = jest.fn().mockResolvedValue({
        user_id: 1,
        code: 'ABC123',
      });
      referralRepository.findReferralByReferredUserId = jest.fn().mockResolvedValue(null);
      referralRepository.createReferral = jest.fn().mockResolvedValue(10);

      const result = await referralService.createReferralOnSignup(2, 'ABC123', {
        alreadyVerified: false,
      });

      expect(result.created).toBe(true);
      expect(result.status).toBe('pending');
      expect(referralRepository.createReferral).toHaveBeenCalledWith(
        expect.objectContaining({
          referrerUserId: 1,
          referredUserId: 2,
          status: 'pending',
        })
      );
    });

    it('caso 2: OAuth já verificado cria referral verified', async () => {
      referralRepository.findCodeByCode = jest.fn().mockResolvedValue({
        user_id: 1,
        code: 'ABC123',
      });
      referralRepository.findReferralByReferredUserId = jest.fn().mockResolvedValue(null);
      referralRepository.createReferral = jest.fn().mockResolvedValue(11);

      const result = await referralService.createReferralOnSignup(3, 'ABC123', {
        alreadyVerified: true,
      });

      expect(result.status).toBe('verified');
    });

    it('caso 3: rejeita autoindicação', async () => {
      referralRepository.findCodeByCode = jest.fn().mockResolvedValue({
        user_id: 5,
        code: 'SELF01',
      });

      const result = await referralService.createReferralOnSignup(5, 'SELF01');
      expect(result.created).toBe(false);
      expect(result.reason).toBe('self_referral');
    });

    it('caso 4: rejeita se usuário já possui indicador', async () => {
      referralRepository.findCodeByCode = jest.fn().mockResolvedValue({
        user_id: 1,
        code: 'ABC123',
      });
      referralRepository.findReferralByReferredUserId = jest.fn().mockResolvedValue({
        referrer_user_id: 1,
      });

      const result = await referralService.createReferralOnSignup(2, 'ABC123');
      expect(result.created).toBe(false);
      expect(result.reason).toBe('already_referred');
    });

    it('caso 6: código inexistente não cria referral', async () => {
      referralRepository.findCodeByCode = jest.fn().mockResolvedValue(null);

      const result = await referralService.createReferralOnSignup(2, 'INVALID');
      expect(result.created).toBe(false);
      expect(result.reason).toBe('invalid_code');
    });
  });

  describe('markVerified', () => {
    it('caso 1: promove pending para verified', async () => {
      referralRepository.markReferralVerified = jest.fn().mockResolvedValue(1);
      referralRepository.findReferralByReferredUserId = jest.fn().mockResolvedValue({
        referrer_user_id: 1,
      });

      const result = await referralService.markVerified(2);
      expect(result.updated).toBe(true);
    });

    it('caso 5: duplo processamento é idempotente', async () => {
      referralRepository.markReferralVerified = jest.fn().mockResolvedValue(0);
      const result = await referralService.markVerified(2);
      expect(result.updated).toBe(false);
    });
  });

  describe('attachReferralToLoggedInUser', () => {
    it('caso 7: usuário existente com indicador não altera', async () => {
      referralRepository.findCodeByCode = jest.fn().mockResolvedValue({
        user_id: 3,
        code: 'NEW123',
      });
      referralRepository.findReferralByReferredUserId = jest.fn().mockResolvedValue({
        referrer_user_id: 1,
      });

      const result = await referralService.attachReferralToLoggedInUser(2, 'NEW123');
      expect(result.attached).toBe(false);
      expect(result.reason).toBe('already_referred');
    });

    it('caso 7b: dono do código não vincula', async () => {
      referralRepository.findCodeByCode = jest.fn().mockResolvedValue({
        user_id: 2,
        code: 'OWN123',
      });

      const result = await referralService.attachReferralToLoggedInUser(2, 'OWN123');
      expect(result.attached).toBe(false);
      expect(result.reason).toBe('own_code');
    });
  });

  describe('computeTier via getMyReferral', () => {
    it('caso 9: tier calculado no backend — embaixador com 5 verificados', async () => {
      referralRepository.findCodeByUserId = jest.fn().mockResolvedValue({ code: 'TST123' });
      referralRepository.getUserName = jest.fn();
      referralRepository.countByReferrer = jest.fn().mockResolvedValue({
        total: 5,
        verified: 5,
        pending: 0,
      });
      referralRepository.listReferralsByReferrer = jest.fn().mockResolvedValue([]);

      const data = await referralService.getMyReferral(10);
      expect(data.tier).toBe('embaixador');
      expect(data.verified_count).toBe(5);
    });
  });
});
