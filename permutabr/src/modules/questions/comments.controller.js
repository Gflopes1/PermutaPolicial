const commentsService = require('./comments.service');
const ApiError = require('../../core/utils/ApiError');

class CommentsController {
  async getComments(req, res, next) {
    try {
      const filters = {
        page: parseInt(req.query.page) || 1,
        perPage: parseInt(req.query.per_page) || 20,
        sort: req.query.sort || 'newest'
      };

      const result = await commentsService.getComments(req.params.id, filters);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async getReplies(req, res, next) {
    try {
      const filters = {
        page: parseInt(req.query.page) || 1,
        perPage: parseInt(req.query.per_page) || 10
      };

      const replies = await commentsService.getReplies(req.params.id, filters);
      res.json(replies);
    } catch (error) {
      next(error);
    }
  }

  async createComment(req, res, next) {
    try {
      const userId = req.user.id;
      const { content, parent_id } = req.body;

      const comment = await commentsService.createComment(
        req.params.id,
        userId,
        content,
        parent_id
      );
      res.status(201).json(comment);
    } catch (error) {
      next(error);
    }
  }

  async updateComment(req, res, next) {
    try {
      const userId = req.user.id;
      const { content } = req.body;

      const comment = await commentsService.updateComment(req.params.id, userId, content);
      res.json(comment);
    } catch (error) {
      next(error);
    }
  }

  async deleteComment(req, res, next) {
    try {
      const userId = req.user.id;
      await commentsService.deleteComment(req.params.id, userId);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }

  async toggleLike(req, res, next) {
    try {
      const userId = req.user.id;
      const result = await commentsService.toggleLike(req.params.id, userId);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async reportComment(req, res, next) {
    try {
      const userId = req.user.id;
      const { reason, note } = req.body;

      await commentsService.reportComment(req.params.id, userId, reason, note);
      res.status(201).json({ message: 'Comentário reportado com sucesso' });
    } catch (error) {
      next(error);
    }
  }

  async moderateComment(req, res, next) {
    try {
      const moderatorId = req.user.id;
      const { action, note } = req.body;

      await commentsService.moderateComment(req.params.id, moderatorId, action, note);
      res.json({ message: 'Ação de moderação aplicada com sucesso' });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new CommentsController();


