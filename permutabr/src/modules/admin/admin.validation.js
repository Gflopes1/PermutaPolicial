// /src/modules/admin/admin.validation.js

const { Joi, Segments } = require('celebrate');

// Um esquema reutilizável para qualquer rota que processe um ID numérico
const processByIdSchema = {
  [Segments.PARAMS]: Joi.object().keys({
    id: Joi.number().integer().required(),
  }),
};

module.exports = {
  processaSugestao: processByIdSchema,
  processaVerificacao: processByIdSchema,
};