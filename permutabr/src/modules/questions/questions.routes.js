const express = require('express');
const { celebrate } = require('celebrate');
const questionsController = require('./questions.controller');
const questionsValidation = require('./questions.validation');
const authMiddleware = require('../../core/middlewares/auth.middleware');
const adminMiddleware = require('../../core/middlewares/admin.middleware');
const embaixadorMiddleware = require('../../core/middlewares/embaixador.middleware');
const premiumMiddleware = require('../../core/middlewares/premium.middleware');
const usageLimitMiddleware = require('../../core/middlewares/usageLimit.middleware');

const router = express.Router();

router.get(
  '/',
  celebrate(questionsValidation.getQuestions),
  questionsController.getQuestions
);

// Endpoints para filtros - DEVEM vir ANTES das rotas com :id
router.get(
  '/assuntos',
  questionsController.getAllAssuntos
);

router.get(
  '/subassuntos',
  questionsController.getSubassuntosByAssunto
);

// Modo Prática - rotas específicas antes de :id
router.get(
  '/practice/next',
  authMiddleware,
  premiumMiddleware, // Verifica status premium
  usageLimitMiddleware('practice_questions', 10), // Limite Free: 10 questões/dia
  celebrate(questionsValidation.getNextPracticeQuestion),
  questionsController.getNextPracticeQuestion
);

router.post(
  '/practice/answer',
  authMiddleware,
  premiumMiddleware, // Verifica status premium
  questionsController.savePracticeAnswer
);

router.get(
  '/practice/history',
  authMiddleware,
  questionsController.getPracticeHistory
);

router.delete(
  '/practice/reset/:questionId',
  authMiddleware,
  questionsController.resetPracticeAnswer
);

// Admin - Aprovar questões (embaixador OU moderador/admin) - rotas específicas antes de :id
router.get(
  '/admin/pending',
  authMiddleware,
  embaixadorMiddleware, // Embaixador pode ver questões pendentes
  questionsController.getPendingQuestions
);

router.put(
  '/admin/:id/approve',
  authMiddleware,
  embaixadorMiddleware, // Embaixador pode aprovar
  questionsController.approveQuestion
);

router.put(
  '/admin/:id/reject',
  authMiddleware,
  embaixadorMiddleware, // Embaixador pode rejeitar
  questionsController.rejectQuestion
);

// Rotas com parâmetros dinâmicos DEVEM vir por último
router.get(
  '/:id',
  celebrate(questionsValidation.getQuestionById),
  questionsController.getQuestionById
);

router.post(
  '/',
  authMiddleware,
  adminMiddleware,
  celebrate(questionsValidation.createQuestion),
  questionsController.createQuestion
);

router.put(
  '/:id',
  authMiddleware,
  adminMiddleware,
  celebrate(questionsValidation.updateQuestion),
  questionsController.updateQuestion
);

router.delete(
  '/:id',
  authMiddleware,
  adminMiddleware,
  celebrate(questionsValidation.deleteQuestion),
  questionsController.deleteQuestion
);

module.exports = router;


