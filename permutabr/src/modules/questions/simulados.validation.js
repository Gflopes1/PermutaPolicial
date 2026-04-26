const { celebrate, Joi, Segments } = require('celebrate');

module.exports = {
  createSimulado: {
    [Segments.BODY]: Joi.object().keys({
      type: Joi.string().valid('random', 'by_subject').required(),
      questionCount: Joi.number().integer().min(1).max(120).when('type', {
        is: 'random',
        then: Joi.required()
      }),
      subjects: Joi.object().when('type', {
        is: 'by_subject',
        then: Joi.required()
      }),
      subassuntos: Joi.array().items(Joi.string()).optional(),
      tipo: Joi.string().valid('mc', 'vf').optional(),
      titulo: Joi.string().optional(),
      timerSeconds: Joi.number().integer().min(60).max(7200).default(3600)
    })
  },

  startSimulado: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required()
    })
  },

  getCurrentQuestion: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required()
    }),
    [Segments.QUERY]: Joi.object().keys({
      ordem: Joi.number().integer().min(1).default(1)
    })
  },

  submitAnswer: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required()
    }),
    [Segments.BODY]: Joi.object().keys({
      question_id: Joi.number().integer().required(),
      ordem: Joi.number().integer().min(1).required(),
      answer_given: Joi.string().required(),
      time_spent_seconds: Joi.number().integer().min(0).required(),
      server_start_time: Joi.number().integer().required()
    })
  },

  getResult: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required()
    })
  }
};


