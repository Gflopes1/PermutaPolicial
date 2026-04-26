const simuladosService = require('../simulados.service');
const questionsService = require('../questions.service');
const paymentsRepository = require('../payments.repository');
const ApiError = require('../../../core/utils/ApiError');

jest.mock('../questions.service');
jest.mock('../simulados.repository');
jest.mock('../payments.repository');

describe('SimuladosService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('checkUserLimits', () => {
    it('deve permitir usuário premium criar simulado com até 120 questões', async () => {
      const result = await simuladosService.checkUserLimits(1, true, 120);
      expect(result).toBe(true);
    });

    it('deve rejeitar usuário premium com mais de 120 questões', async () => {
      await expect(
        simuladosService.checkUserLimits(1, true, 121)
      ).rejects.toThrow(ApiError);
    });

    it('deve rejeitar usuário free com mais de 10 questões', async () => {
      const simuladosRepository = require('../simulados.repository');
      simuladosRepository.getDailyAttemptsCount = jest.fn().resolvedValue(0);

      await expect(
        simuladosService.checkUserLimits(1, false, 11)
      ).rejects.toThrow(ApiError);
    });

    it('deve verificar limite diário para usuário free', async () => {
      const simuladosRepository = require('../simulados.repository');
      simuladosRepository.getDailyAttemptsCount = jest.fn().resolvedValue(5);

      await expect(
        simuladosService.checkUserLimits(1, false, 6)
      ).rejects.toThrow(ApiError);
    });
  });

  describe('createSimulado', () => {
    it('deve criar simulado aleatório', async () => {
      const simuladosRepository = require('../simulados.repository');
      questionsService.getRandomQuestions = jest.fn().resolvedValue([
        { id: 1 }, { id: 2 }, { id: 3 }
      ]);
      simuladosRepository.create = jest.fn().resolvedValue(1);
      simuladosRepository.addQuestions = jest.fn().resolvedValue(true);
      simuladosRepository.findById = jest.fn().resolvedValue({ id: 1 });

      const result = await simuladosService.createSimulado(1, false, {
        type: 'random',
        questionCount: 3
      });

      expect(result).toBeDefined();
      expect(simuladosRepository.create).toHaveBeenCalled();
    });
  });
});


