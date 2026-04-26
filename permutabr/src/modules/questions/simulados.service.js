const simuladosRepository = require('./simulados.repository');
const questionsService = require('./questions.service');
const paymentsRepository = require('./payments.repository');
const ApiError = require('../../core/utils/ApiError');

class SimuladosService {
  async getCreateOptions() {
    return {
      subjects: [
        'Direitos',
        'Português',
        'CTB',
        'Informática',
        'Raciocínio Lógico',
        'Contabilidade Geral',
        'Estatística',
        'Física',
        'Inglês',
        'Espanhol'
      ],
      maxQuestions: {
        free: 10,
        premium: 120
      }
    };
  }

  async checkUserLimits(userId, isPremium, questionCount) {
    if (isPremium) {
      if (questionCount > 120) {
        throw new ApiError(400, 'Usuário premium pode criar simulados com até 120 questões');
      }
      return true;
    }

    const today = new Date().toISOString().split('T')[0];
    const dailyCount = await simuladosRepository.getDailyAttemptsCount(userId, today);

    if (dailyCount + questionCount > 10) {
      throw new ApiError(403, `Limite diário de 10 questões atingido. Restam ${10 - dailyCount} questões hoje.`);
    }

    if (questionCount > 10) {
      throw new ApiError(400, 'Usuário grátis pode criar simulados com até 10 questões');
    }

    return true;
  }

  async createSimulado(userId, isPremium, config) {
    const { type, questionCount, subjects, subassuntos = [], tipo: tipoFiltro = null } = config;

    await this.checkUserLimits(userId, isPremium, questionCount);

    let questionIds = [];

    if (type === 'random') {
      const questions = await questionsService.getRandomQuestions({}, [], { subassuntos, tipo: tipoFiltro });
      questionIds = questions.slice(0, questionCount).map(q => q.id);
    } else if (type === 'by_subject') {
      const subjectsConfig = {};
      for (const [assunto, count] of Object.entries(subjects)) {
        subjectsConfig[assunto] = parseInt(count);
      }

      const questions = await questionsService.getRandomQuestions(subjectsConfig, [], { subassuntos, tipo: tipoFiltro });
      questionIds = questions.map(q => q.id);
    } else {
      throw new ApiError(400, 'Tipo de simulado inválido');
    }

    if (questionIds.length === 0) {
      throw new ApiError(400, 'Nenhuma questão encontrada com os critérios especificados');
    }

    const titulo = config.titulo || `Simulado ${new Date().toLocaleDateString('pt-BR')}`;
    const simuladoId = await simuladosRepository.create(userId, titulo, config);
    await simuladosRepository.addQuestions(simuladoId, questionIds);

    return await simuladosRepository.findById(simuladoId);
  }

  async startSimulado(simuladoId, userId) {
    const simulado = await simuladosRepository.findById(simuladoId);
    if (!simulado) {
      throw new ApiError(404, 'Simulado não encontrado');
    }

    if (simulado.user_id !== userId) {
      throw new ApiError(403, 'Você não tem permissão para iniciar este simulado');
    }

    if (simulado.started_at) {
      throw new ApiError(400, 'Simulado já foi iniciado');
    }

    await simuladosRepository.start(simuladoId);

    const questions = await simuladosRepository.findQuestionsBySimuladoId(simuladoId);
    const firstQuestion = questions[0];

    if (firstQuestion.alternativas) {
      try {
        firstQuestion.alternativas = JSON.parse(firstQuestion.alternativas);
      } catch (e) {
        firstQuestion.alternativas = [];
      }
    }

    const config = typeof simulado.config === 'string' 
      ? JSON.parse(simulado.config) 
      : simulado.config;

    return {
      simulado: {
        id: simulado.id,
        started_at: simulado.started_at
      },
      question: firstQuestion,
      questionNumber: 1,
      totalQuestions: questions.length,
      timerSeconds: config.timerSeconds || 3600,
      serverTimestamp: Math.floor(Date.now() / 1000)
    };
  }

  async getCurrentQuestion(simuladoId, ordem, userId) {
    const simulado = await simuladosRepository.findById(simuladoId);
    if (!simulado) {
      throw new ApiError(404, 'Simulado não encontrado');
    }

    if (simulado.user_id !== userId) {
      throw new ApiError(403, 'Você não tem permissão para acessar este simulado');
    }

    if (!simulado.started_at) {
      throw new ApiError(400, 'Simulado não foi iniciado');
    }

    const question = await simuladosRepository.getCurrentQuestion(simuladoId, ordem);
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

    const config = typeof question.config === 'string' 
      ? JSON.parse(question.config) 
      : question.config;

    const questions = await simuladosRepository.findQuestionsBySimuladoId(simuladoId);

    return {
      question,
      questionNumber: ordem,
      totalQuestions: questions.length,
      timerSeconds: config.timerSeconds || 3600,
      serverTimestamp: Math.floor(Date.now() / 1000)
    };
  }

  async submitAnswer(simuladoId, questionId, ordem, answerGiven, timeSpentSeconds, userId, serverStartTime) {
    const simulado = await simuladosRepository.findById(simuladoId);
    if (!simulado) {
      throw new ApiError(404, 'Simulado não encontrado');
    }

    if (simulado.user_id !== userId) {
      throw new ApiError(403, 'Você não tem permissão para responder este simulado');
    }

    if (!simulado.started_at) {
      throw new ApiError(400, 'Simulado não foi iniciado');
    }

    const question = await simuladosRepository.getCurrentQuestion(simuladoId, ordem);
    if (!question) {
      throw new ApiError(404, 'Questão não encontrada');
    }

    if (question.id !== questionId) {
      throw new ApiError(400, 'Questão não corresponde ao simulado');
    }

    const config = typeof simulado.config === 'string' 
      ? JSON.parse(simulado.config) 
      : simulado.config;

    const elapsedTime = Math.floor(Date.now() / 1000) - serverStartTime;
    if (elapsedTime > (config.timerSeconds || 3600)) {
      await simuladosRepository.finish(simuladoId);
      throw new ApiError(400, 'Tempo esgotado. Simulado finalizado automaticamente.');
    }

    // Normaliza resposta correta para questões VF (C/E -> a/b)
    let respostaCorretaNormalizada = question.resposta_correta.toUpperCase();
    if (question.tipo === 'vf' && question.alternativas && question.alternativas.length === 2) {
      if (respostaCorretaNormalizada === 'C') {
        respostaCorretaNormalizada = 'A'; // Primeira alternativa
      } else if (respostaCorretaNormalizada === 'E') {
        respostaCorretaNormalizada = 'B'; // Segunda alternativa
      }
    }

    const correct = answerGiven.toUpperCase() === respostaCorretaNormalizada;
    await simuladosRepository.recordAttempt(
      userId,
      simuladoId,
      questionId,
      answerGiven,
      correct,
      timeSpentSeconds
    );

    const questions = await simuladosRepository.findQuestionsBySimuladoId(simuladoId);
    const isLast = ordem >= questions.length;

    if (isLast) {
      await simuladosRepository.finish(simuladoId);
    }

    return {
      correct,
      isLast,
      nextQuestionNumber: isLast ? null : ordem + 1
    };
  }

  async getResult(simuladoId, userId) {
    const simulado = await simuladosRepository.findById(simuladoId);
    if (!simulado) {
      throw new ApiError(404, 'Simulado não encontrado');
    }

    if (simulado.user_id !== userId) {
      throw new ApiError(403, 'Você não tem permissão para acessar este resultado');
    }

    const result = await simuladosRepository.getResult(simuladoId, userId);

    for (const attempt of result.attempts) {
      if (attempt.alternativas) {
        try {
          attempt.alternativas = JSON.parse(attempt.alternativas);
        } catch (e) {
          attempt.alternativas = [];
        }
      }
    }

    return result;
  }
}

module.exports = new SimuladosService();


