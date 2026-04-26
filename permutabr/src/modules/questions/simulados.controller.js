const simuladosService = require('./simulados.service');
const ApiError = require('../../core/utils/ApiError');

class SimuladosController {
  async getCreateOptions(req, res, next) {
    try {
      const options = await simuladosService.getCreateOptions();
      res.json(options);
    } catch (error) {
      next(error);
    }
  }

  async createSimulado(req, res, next) {
    try {
      const userId = req.user.id;
      const isPremium = req.user.is_premium || false;

      const simulado = await simuladosService.createSimulado(userId, isPremium, req.body);
      res.status(201).json(simulado);
    } catch (error) {
      next(error);
    }
  }

  async startSimulado(req, res, next) {
    try {
      const userId = req.user.id;
      const result = await simuladosService.startSimulado(req.params.id, userId);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async getCurrentQuestion(req, res, next) {
    try {
      const userId = req.user.id;
      const ordem = parseInt(req.query.ordem) || 1;
      const result = await simuladosService.getCurrentQuestion(req.params.id, ordem, userId);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async submitAnswer(req, res, next) {
    try {
      const userId = req.user.id;
      const { question_id, ordem, answer_given, time_spent_seconds, server_start_time } = req.body;

      const result = await simuladosService.submitAnswer(
        req.params.id,
        question_id,
        ordem,
        answer_given,
        time_spent_seconds,
        userId,
        server_start_time
      );
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async getResult(req, res, next) {
    try {
      const userId = req.user.id;
      const result = await simuladosService.getResult(req.params.id, userId);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new SimuladosController();


