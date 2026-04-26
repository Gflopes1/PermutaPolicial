const questionsService = require('./questions.service');
const ApiError = require('../../core/utils/ApiError');

class QuestionsController {
  async getQuestions(req, res, next) {
    try {
      const filters = {
        assunto: req.query.assunto,
        subassunto: req.query.subassunto,
        tipo: req.query.tipo,
        page: parseInt(req.query.page) || 1,
        perPage: parseInt(req.query.per_page) || 20,
        search: req.query.search
      };

      const result = await questionsService.getQuestions(filters);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async getQuestionById(req, res, next) {
    try {
      const question = await questionsService.getQuestionById(req.params.id);
      res.json(question);
    } catch (error) {
      next(error);
    }
  }

  async createQuestion(req, res, next) {
    try {
      const question = await questionsService.createQuestion(req.body);
      res.status(201).json(question);
    } catch (error) {
      next(error);
    }
  }

  async updateQuestion(req, res, next) {
    try {
      const question = await questionsService.updateQuestion(req.params.id, req.body);
      res.json(question);
    } catch (error) {
      next(error);
    }
  }

  async deleteQuestion(req, res, next) {
    try {
      await questionsService.deleteQuestion(req.params.id);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }

  // Modo Prática
  async getNextPracticeQuestion(req, res, next) {
    try {
      const userId = req.user.id;
      const subjects = req.query.subjects ? req.query.subjects.split(',') : [];
      const subassuntos = req.query.subassuntos ? req.query.subassuntos.split(',') : [];
      const tipo = req.query.tipo || null;
      const question = await questionsService.getNextPracticeQuestion(userId, { subjects, subassuntos, tipo });
      res.json(question);
    } catch (error) {
      next(error);
    }
  }

  async savePracticeAnswer(req, res, next) {
    try {
      const userId = req.user.id;
      const { question_id, answer_given, time_spent_seconds } = req.body;
      const result = await questionsService.savePracticeAnswer(
        userId,
        question_id,
        answer_given,
        time_spent_seconds || 0
      );
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async getPracticeHistory(req, res, next) {
    try {
      const userId = req.user.id;
      const filters = {
        page: parseInt(req.query.page) || 1,
        perPage: Math.min(parseInt(req.query.per_page) || 5, 20), // Carrega 5 inicialmente, máximo 20
        assunto: req.query.assunto
      };
      const result = await questionsService.getPracticeHistory(userId, filters);
      res.json(result);
    } catch (error) {
      next(error);
      }
  }

  async resetPracticeAnswer(req, res, next) {
    try {
      const userId = req.user.id;
      const questionId = parseInt(req.params.questionId);
      await questionsService.resetPracticeAnswer(userId, questionId);
      res.json({ message: 'Questão resetada com sucesso' });
    } catch (error) {
      next(error);
    }
  }

  // Admin
  async getPendingQuestions(req, res, next) {
    try {
      const filters = {
        page: parseInt(req.query.page) || 1,
        perPage: Math.min(parseInt(req.query.per_page) || 5, 20), // Carrega 5 inicialmente, máximo 20
        assunto: req.query.assunto,
        subassunto: req.query.subassunto,
        tipo: req.query.tipo
      };
      const result = await questionsService.getPendingQuestions(filters);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async approveQuestion(req, res, next) {
    try {
      const approvedBy = req.user.id;
      const question = await questionsService.approveQuestion(req.params.id, approvedBy);
      res.json(question);
    } catch (error) {
      next(error);
    }
  }

  async rejectQuestion(req, res, next) {
    try {
      const approvedBy = req.user.id;
      const question = await questionsService.rejectQuestion(req.params.id, approvedBy);
      res.json(question);
    } catch (error) {
      next(error);
    }
  }

  // Busca subassuntos por assunto
  async getSubassuntosByAssunto(req, res, next) {
    try {
      const { assunto } = req.query;
      if (!assunto) {
        return res.status(400).json({ error: 'Assunto é obrigatório' });
      }
      const subassuntos = await questionsService.getSubassuntosByAssunto(assunto);
      res.json(subassuntos);
    } catch (error) {
      next(error);
    }
  }

  // Busca todos os assuntos
  async getAllAssuntos(req, res, next) {
    try {
      const assuntos = await questionsService.getAllAssuntos();
      res.json(assuntos);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new QuestionsController();


