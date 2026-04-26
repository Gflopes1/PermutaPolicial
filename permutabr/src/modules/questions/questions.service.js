const questionsRepository = require('./questions.repository');
const ApiError = require('../../core/utils/ApiError');

class QuestionsService {
  async getQuestions(filters) {
    return await questionsRepository.findAll(filters);
  }

  async getQuestionById(id) {
    const question = await questionsRepository.findById(id);
    if (!question) {
      throw new ApiError(404, 'Questão não encontrada');
    }

    if (question.alternativas) {
      try {
        question.alternativas = JSON.parse(question.alternativas);
      } catch (e) {
        question.alternativas = [];
      }
    }

    return question;
  }

  async createQuestion(questionData) {
    if (!questionData.alternativas || !Array.isArray(questionData.alternativas)) {
      throw new ApiError(400, 'Alternativas devem ser um array');
    }

    if (questionData.tipo === 'vf' && questionData.alternativas.length !== 2) {
      throw new ApiError(400, 'Questões V/F devem ter exatamente 2 alternativas');
    }

    if (!['a', 'b', 'c', 'd', 'e', 'V', 'F'].includes(questionData.resposta_correta)) {
      throw new ApiError(400, 'Resposta correta inválida');
    }

    const id = await questionsRepository.create(questionData);
    return await this.getQuestionById(id);
  }

  async updateQuestion(id, questionData) {
    const existing = await questionsRepository.findById(id);
    if (!existing) {
      throw new ApiError(404, 'Questão não encontrada');
    }

    if (questionData.alternativas && !Array.isArray(questionData.alternativas)) {
      throw new ApiError(400, 'Alternativas devem ser um array');
    }

    await questionsRepository.update(id, questionData);
    return await this.getQuestionById(id);
  }

  async deleteQuestion(id) {
    const existing = await questionsRepository.findById(id);
    if (!existing) {
      throw new ApiError(404, 'Questão não encontrada');
    }

    await questionsRepository.delete(id);
    return true;
  }

  async getRandomQuestions(subjectsConfig, excludeIds = [], { subassuntos = [], tipo = null } = {}) {
    const questions = await questionsRepository.findRandomBySubjects(subjectsConfig, excludeIds, { subassuntos, tipo });
    
    for (const question of questions) {
      if (question.alternativas) {
        try {
          question.alternativas = JSON.parse(question.alternativas);
        } catch (e) {
          question.alternativas = [];
        }
      }
    }

    return questions;
  }

  // Modo Prática
  async getNextPracticeQuestion(userId, { subjects = [], subassuntos = [], tipo = null } = {}) {
    const question = await questionsRepository.findNextUnanswered(userId, { subjects, subassuntos, tipo });
    if (!question) {
      throw new ApiError(404, 'Nenhuma questão disponível');
    }
    return question;
  }

  async savePracticeAnswer(userId, questionId, answerGiven, timeSpentSeconds) {
    const question = await questionsRepository.findById(questionId);
    if (!question) {
      throw new ApiError(404, 'Questão não encontrada');
    }

    // Normaliza resposta correta para questões VF (C/E -> a/b)
    let respostaCorretaNormalizada = question.resposta_correta.toLowerCase();
    if (question.tipo === 'vf' && question.alternativas && question.alternativas.length === 2) {
      const respostaUpper = question.resposta_correta.toUpperCase();
      if (respostaUpper === 'C') {
        respostaCorretaNormalizada = 'a'; // Primeira alternativa
      } else if (respostaUpper === 'E') {
        respostaCorretaNormalizada = 'b'; // Segunda alternativa
      }
    }

    const correct = answerGiven.toLowerCase() === respostaCorretaNormalizada;
    await questionsRepository.savePracticeAnswer(userId, questionId, answerGiven, correct, timeSpentSeconds);
    
    return {
      correct,
      correctAnswer: respostaCorretaNormalizada,
      explanation: question.explicacao
    };
  }

  async getPracticeHistory(userId, filters) {
    return await questionsRepository.findPracticeHistory(userId, filters);
  }

  async resetPracticeAnswer(userId, questionId) {
    await questionsRepository.resetPracticeAnswer(userId, questionId);
    return true;
  }

  // Admin
  async getPendingQuestions(filters) {
    return await questionsRepository.findPendingApproval({
      page: filters.page || 1,
      perPage: filters.perPage || 5,
      assunto: filters.assunto,
      subassunto: filters.subassunto,
      tipo: filters.tipo
    });
  }

  async approveQuestion(questionId, approvedBy) {
    await questionsRepository.approveQuestion(questionId, approvedBy);
    return await this.getQuestionById(questionId);
  }

  async rejectQuestion(questionId, approvedBy) {
    await questionsRepository.rejectQuestion(questionId, approvedBy);
    return await this.getQuestionById(questionId);
  }

  // Busca subassuntos por assunto
  async getSubassuntosByAssunto(assunto) {
    return await questionsRepository.findSubassuntosByAssunto(assunto);
  }

  // Busca todos os assuntos
  async getAllAssuntos() {
    return await questionsRepository.findAllAssuntos();
  }
}

module.exports = new QuestionsService();


