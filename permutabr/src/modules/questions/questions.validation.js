const { celebrate, Joi, Segments } = require('celebrate');

module.exports = {
  getQuestions: {
    [Segments.QUERY]: Joi.object().keys({
      assunto: Joi.string().optional(),
      subassunto: Joi.string().optional(),
      tipo: Joi.string().valid('mc', 'vf').optional(),
      page: Joi.number().integer().min(1).optional(),
      per_page: Joi.number().integer().min(1).max(100).optional(),
      search: Joi.string().optional()
    })
  },

  getQuestionById: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required()
    })
  },

  createQuestion: {
    [Segments.BODY]: Joi.object().keys({
      pergunta: Joi.string().required(),
      alternativas: Joi.array().items(Joi.string()).min(2).required(),
      resposta_correta: Joi.string().valid('a', 'b', 'c', 'd', 'e', 'V', 'F').required(),
      explicacao: Joi.string().optional().allow(null, ''),
      assunto: Joi.string().required(),
      subassunto: Joi.string().optional().allow(null, ''),
      tipo: Joi.string().valid('mc', 'vf').default('mc'),
      origem: Joi.string().optional().allow(null, '')
    })
  },

  updateQuestion: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required()
    }),
    [Segments.BODY]: Joi.object().keys({
      pergunta: Joi.string().optional(),
      alternativas: Joi.array().items(Joi.string()).min(2).optional(),
      resposta_correta: Joi.string().valid('a', 'b', 'c', 'd', 'e', 'V', 'F').optional(),
      explicacao: Joi.string().optional().allow(null, ''),
      assunto: Joi.string().optional(),
      subassunto: Joi.string().optional().allow(null, ''),
      tipo: Joi.string().valid('mc', 'vf').optional(),
      origem: Joi.string().optional().allow(null, '')
    })
  },

  deleteQuestion: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required()
    })
  },

  getNextPracticeQuestion: {
    [Segments.QUERY]: Joi.object().keys({
      subjects: Joi.string().optional(),
      subassuntos: Joi.string().optional(),
      tipo: Joi.string().valid('mc', 'vf').optional()
    })
  }
};


