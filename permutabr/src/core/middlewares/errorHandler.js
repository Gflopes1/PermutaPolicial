// /src/core/middlewares/errorHandler.js

const { isCelebrateError } = require('celebrate');
const ApiError = require('../utils/ApiError');

const errorHandler = (err, req, res, next) => {
  let statusCode = 500;
  let message = 'Ocorreu um erro interno no servidor.';

  // Log do erro no console para depuração (importante em desenvolvimento)
  console.error(err);

  // Erro de validação do Celebrate/Joi
  if (isCelebrateError(err)) {
    statusCode = 400; // Bad Request
    // Pega a primeira mensagem de erro dos detalhes da validação
    message = err.details.get('body')?.details[0]?.message || 'Erro de validação.';
  }

  // Erro customizado da nossa classe ApiError
  if (err instanceof ApiError) {
    statusCode = err.statusCode;
    message = err.message;
  }

  // Envia a resposta de erro padronizada
  res.status(statusCode).json({
    status: 'error',
    message: message,
  });
};

module.exports = errorHandler;