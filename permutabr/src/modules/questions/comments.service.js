const commentsRepository = require('./comments.repository');
const ApiError = require('../../core/utils/ApiError');

class CommentsService {
  RATE_LIMIT_MINUTES = 1;
  RATE_LIMIT_MAX_COMMENTS = 5;

  async getComments(questionId, filters) {
    return await commentsRepository.findByQuestionId(questionId, filters);
  }

  async getReplies(parentId, filters) {
    return await commentsRepository.findReplies(parentId, filters);
  }

  async createComment(questionId, userId, content, parentId = null) {
    const recentCount = await commentsRepository.getRecentCommentsByUser(
      userId,
      this.RATE_LIMIT_MINUTES
    );

    if (recentCount >= this.RATE_LIMIT_MAX_COMMENTS) {
      throw new ApiError(429, `Limite de ${this.RATE_LIMIT_MAX_COMMENTS} comentários por minuto atingido`);
    }

    if (parentId) {
      const parent = await commentsRepository.findById(parentId);
      if (!parent) {
        throw new ApiError(404, 'Comentário pai não encontrado');
      }

      if (parent.parent_id) {
        throw new ApiError(400, 'Não é possível responder a uma resposta (máximo 2 níveis)');
      }
    }

    const id = await commentsRepository.create(questionId, userId, content, parentId);
    return await commentsRepository.findById(id);
  }

  async updateComment(id, userId, content) {
    const comment = await commentsRepository.findById(id);
    if (!comment) {
      throw new ApiError(404, 'Comentário não encontrado');
    }

    if (comment.user_id !== userId) {
      throw new ApiError(403, 'Você não tem permissão para editar este comentário');
    }

    if (comment.deleted_at) {
      throw new ApiError(400, 'Não é possível editar um comentário deletado');
    }

    await commentsRepository.update(id, content);
    return await commentsRepository.findById(id);
  }

  async deleteComment(id, userId) {
    const comment = await commentsRepository.findById(id);
    if (!comment) {
      throw new ApiError(404, 'Comentário não encontrado');
    }

    if (comment.user_id !== userId) {
      throw new ApiError(403, 'Você não tem permissão para deletar este comentário');
    }

    await commentsRepository.delete(id);
    return true;
  }

  async toggleLike(commentId, userId) {
    const comment = await commentsRepository.findById(commentId);
    if (!comment) {
      throw new ApiError(404, 'Comentário não encontrado');
    }

    return await commentsRepository.toggleLike(commentId, userId);
  }

  async reportComment(commentId, userId, reason, note) {
    const comment = await commentsRepository.findById(commentId);
    if (!comment) {
      throw new ApiError(404, 'Comentário não encontrado');
    }

    if (comment.user_id === userId) {
      throw new ApiError(400, 'Você não pode reportar seu próprio comentário');
    }

    await commentsRepository.report(commentId, userId, reason, note);
    return true;
  }

  async moderateComment(commentId, moderatorId, action, note) {
    const comment = await commentsRepository.findById(commentId);
    if (!comment) {
      throw new ApiError(404, 'Comentário não encontrado');
    }

    switch (action) {
      case 'hide':
        await commentsRepository.hide(commentId);
        break;
      case 'unhide':
        await commentsRepository.unhide(commentId);
        break;
      case 'delete':
        await commentsRepository.delete(commentId);
        break;
      default:
        throw new ApiError(400, 'Ação de moderação inválida');
    }

    await commentsRepository.logModeration(commentId, moderatorId, action, note);
    return true;
  }
}

module.exports = new CommentsService();


