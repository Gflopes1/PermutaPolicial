// /src/modules/permutas/permutas.validation.js

const { Joi, Segments } = require('celebrate');

module.exports = {
    // GET /api/permutas/matches
    findMatches: {
        // A validação de query agora está vazia.
        [Segments.QUERY]: Joi.object().keys({}),
    },
};