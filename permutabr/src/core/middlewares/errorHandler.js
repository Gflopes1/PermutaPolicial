// /src/core/middlewares/errorHandler.js

const { isCelebrateError } = require('celebrate');
const ApiError = require('../utils/ApiError');

/**
 * Middleware centralizado para tratamento de erros
 */
const errorHandler = (err, req, res, next) => {
  // Se a resposta já foi enviada, delega para o handler padrão do Express
  if (res.headersSent) {
    return next(err);
  }

  let errorResponse;

  // 1. Erro de validação do Celebrate/Joi
  if (isCelebrateError(err)) {
    const validationDetails = [];
    
    // Coleta todos os erros de validação
    for (const [segment, joiError] of err.details.entries()) {
      joiError.details.forEach((detail) => {
        validationDetails.push({
          field: detail.path.join('.'),
          message: detail.message,
          segment: segment,
        });
      });
    }

    errorResponse = ApiError.badRequest(
      validationDetails[0]?.message || 'Erro de validação',
      { validation: validationDetails }
    );
  }
  // 2. Erro customizado da nossa classe ApiError
  else if (err instanceof ApiError) {
    errorResponse = err;
  }
  // 3. Erro de banco de dados (MySQL/MariaDB)
  else if (err.code && err.code.startsWith('ER_')) {
    errorResponse = ApiError.databaseError(
      'Erro ao processar dados no banco de dados',
      process.env.NODE_ENV === 'development' ? { sqlError: err.message } : null
    );
  }
  // 4. Erro de conexão com banco de dados
  else if (err.code === 'ECONNREFUSED' || err.code === 'ETIMEDOUT') {
    errorResponse = ApiError.serviceUnavailable(
      'Serviço temporariamente indisponível. Tente novamente em alguns instantes.'
    );
  }
  // 5. Erro de autenticação JWT
  else if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    errorResponse = ApiError.unauthorized(
      err.name === 'TokenExpiredError' 
        ? 'Sessão expirada. Faça login novamente.' 
        : 'Token inválido. Faça login novamente.'
    );
  }
  // 6. Erro genérico não tratado
  else {
    errorResponse = ApiError.internalError(
      process.env.NODE_ENV === 'production' 
        ? 'Ocorreu um erro interno no servidor.' 
        : err.message,
      process.env.NODE_ENV === 'development' ? {
        stack: err.stack,
        name: err.name,
        code: err.code,
      } : null
    );
  }

  // Log estruturado do erro
  const logData = {
    timestamp: new Date().toISOString(),
    method: req.method,
    url: req.url,
    statusCode: errorResponse.statusCode,
    errorCode: errorResponse.errorCode,
    message: errorResponse.message,
    ip: req.ip || req.connection.remoteAddress,
    userAgent: req.get('user-agent'),
    ...(process.env.NODE_ENV === 'development' && {
      stack: err.stack,
      originalError: {
        name: err.name,
        message: err.message,
        code: err.code,
      },
    }),
  };

  // Log de erro baseado na severidade
  if (errorResponse.statusCode >= 500) {
    console.error('💥 ERRO DO SERVIDOR:', JSON.stringify(logData, null, 2));
  } else if (errorResponse.statusCode >= 400) {
    console.warn('⚠️  ERRO DO CLIENTE:', JSON.stringify(logData, null, 2));
  } else {
    console.log('ℹ️  ERRO:', JSON.stringify(logData, null, 2));
  }

  // Envia a resposta de erro padronizada
  res.status(errorResponse.statusCode).json(errorResponse.toJSON());
};

module.exports = errorHandler;