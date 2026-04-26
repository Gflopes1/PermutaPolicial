const commentsService = require('../comments.service');
const commentsRepository = require('../comments.repository');
const ApiError = require('../../../core/utils/ApiError');

jest.mock('../comments.repository');

describe('CommentsService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('createComment', () => {
    it('deve criar comentário respeitando rate limit', async () => {
      commentsRepository.getRecentCommentsByUser = jest.fn().resolvedValue(2);
      commentsRepository.findById = jest.fn().resolvedValue(null);
      commentsRepository.create = jest.fn().resolvedValue(1);
      commentsRepository.findById = jest.fn().resolvedValue({ id: 1 });

      const result = await commentsService.createComment(1, 1, 'Teste', null);
      expect(result).toBeDefined();
    });

    it('deve rejeitar se exceder rate limit', async () => {
      commentsRepository.getRecentCommentsByUser = jest.fn().resolvedValue(5);

      await expect(
        commentsService.createComment(1, 1, 'Teste', null)
      ).rejects.toThrow(ApiError);
    });

    it('deve permitir resposta a comentário', async () => {
      commentsRepository.getRecentCommentsByUser = jest.fn().resolvedValue(0);
      commentsRepository.findById = jest.fn()
        .mockResolvedValueOnce({ id: 1, parent_id: null })
        .mockResolvedValueOnce({ id: 2 });
      commentsRepository.create = jest.fn().resolvedValue(2);

      const result = await commentsService.createComment(1, 1, 'Resposta', 1);
      expect(result).toBeDefined();
    });

    it('deve rejeitar resposta a uma resposta', async () => {
      commentsRepository.getRecentCommentsByUser = jest.fn().resolvedValue(0);
      commentsRepository.findById = jest.fn().resolvedValue({ id: 1, parent_id: 5 });

      await expect(
        commentsService.createComment(1, 1, 'Resposta', 1)
      ).rejects.toThrow(ApiError);
    });
  });
});


