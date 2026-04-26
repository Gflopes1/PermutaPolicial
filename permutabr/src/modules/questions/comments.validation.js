const { celebrate, Joi, Segments } = require('celebrate');

module.exports = {
  getComments: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required()
    }),
    [Segments.QUERY]: Joi.object().keys({
      page: Joi.number().integer().min(1).optional(),
      per_page: Joi.number().integer().min(1).max(100).optional(),
      sort: Joi.string().valid('newest', 'oldest').optional()
    })
  },

  getReplies: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required()
    }),
    [Segments.QUERY]: Joi.object().keys({
      page: Joi.number().integer().min(1).optional(),
      per_page: Joi.number().integer().min(1).max(50).optional()
    })
  },

  createComment: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required()
    }),
    [Segments.BODY]: Joi.object().keys({
      content: Joi.string().min(1).max(2000).required(),
      parent_id: Joi.number().integer().optional().allow(null)
    })
  },

  updateComment: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required()
    }),
    [Segments.BODY]: Joi.object().keys({
      content: Joi.string().min(1).max(2000).required()
    })
  },

  deleteComment: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required()
    })
  },

  toggleLike: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required()
    })
  },

  reportComment: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required()
    }),
    [Segments.BODY]: Joi.object().keys({
      reason: Joi.string().valid('spam', 'inappropriate', 'off_topic', 'harassment', 'other').required(),
      note: Joi.string().max(500).optional().allow(null, '')
    })
  },

  moderateComment: {
    [Segments.PARAMS]: Joi.object().keys({
      id: Joi.number().integer().required()
    }),
    [Segments.BODY]: Joi.object().keys({
      action: Joi.string().valid('hide', 'unhide', 'delete', 'approve', 'warn').required(),
      note: Joi.string().max(500).optional().allow(null, '')
    })
  }
};


