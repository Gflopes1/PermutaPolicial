// /src/core/middlewares/errorHandler.js

const { isCelebrateError } = require('celebrate');
const ApiError = require('../utils/ApiError');

const errorHandler = (err, req, res, next) => {
  let statusCode = 500;
  let message = 'Ocorreu um erro interno no servidor.';
  let code = null;
  let details = null;

  // Log estruturado do erro
  const errorLog = {
    timestamp: new Date().toISOString(),
    path: req.path,
    method: req.method,
    message: err.message,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
  };

  console.error('💥 ERRO:', JSON.stringify(errorLog, null, 2));

  // Erro de validação do Celebrate/Joi
  if (isCelebrateError(err)) {
    statusCode = 400;
    const validationDetails = err.details.get('body') || err.details.get('query') || err.details.get('params');
    const firstError = validationDetails?.details?.[0];
    
    // Se for erro customizado, usa a mensagem do contexto
    if (firstError?.type === 'any.custom' && firstError?.context?.message) {
      message = firstError.context.message;
    } else {
      message = firstError?.message || 'Erro de validação.';
    }
    
    details = validationDetails?.details?.map(d => ({
      field: d.path.join('.'),
      message: d.message,
    }));
    code = 'VALIDATION_ERROR';
  }
  // Erro customizado da nossa classe ApiError
  else if (err instanceof ApiError) {
    statusCode = err.statusCode;
    message = err.message;
    code = err.code;
    details = err.details;
  }
  // Erros de banco de dados MySQL/MariaDB
  else if (err.code && err.code.startsWith('ER_')) {
    statusCode = 400;
    code = 'DATABASE_ERROR';
    
    switch (err.code) {
      case 'ER_DUP_ENTRY':
        const sqlMessage = err.sqlMessage || '';
        if (sqlMessage.includes('email') || sqlMessage.includes('EMAIL')) {
          message = 'Este e-mail já está cadastrado.';
          code = 'EMAIL_ALREADY_EXISTS';
        } else if (sqlMessage.includes('id_funcional') || sqlMessage.includes('ID_FUNCIONAL')) {
          message = 'Este ID Funcional já está cadastrado.';
          code = 'ID_FUNCIONAL_ALREADY_EXISTS';
        } else {
          message = 'Este registro já existe no sistema.';
        }
        details = { field: err.sqlMessage?.match(/for key ['`]?([^'`\s]+)['`]?/)?.[1] || 'unknown' };
        break;
      case 'ER_NO_REFERENCED_ROW_2':
        message = 'Referência inválida: o registro relacionado não existe.';
        statusCode = 400;
        break;
      case 'ER_ROW_IS_REFERENCED_2':
        message = 'Não é possível excluir este registro pois ele está sendo utilizado em outras partes do sistema.';
        statusCode = 409;
        break;
      case 'ER_BAD_FIELD_ERROR':
        message = 'Campo inválido na consulta ao banco de dados.';
        break;
      case 'ER_DATA_TOO_LONG':
        message = 'Os dados fornecidos excedem o tamanho máximo permitido.';
        break;
      case 'ER_TRUNCATED_WRONG_VALUE_FOR_FIELD':
        message = 'Valor inválido para o campo especificado.';
        break;
      default:
        message = 'Erro no banco de dados. Tente novamente mais tarde.';
        if (process.env.NODE_ENV === 'development') {
          details = { sqlError: err.sqlMessage };
        }
    }
  }
  // Erros de conexão com banco de dados
  else if (err.code === 'ECONNREFUSED' || err.code === 'ETIMEDOUT') {
    statusCode = 503;
    message = 'Serviço temporariamente indisponível. Tente novamente em alguns instantes.';
    code = 'SERVICE_UNAVAILABLE';
  }
  // Erros de autenticação JWT
  else if (err.name === 'JsonWebTokenError') {
    statusCode = 401;
    message = 'Token de autenticação inválido.';
    code = 'INVALID_TOKEN';
  }
  else if (err.name === 'TokenExpiredError') {
    statusCode = 401;
    message = 'Token de autenticação expirado. Faça login novamente.';
    code = 'TOKEN_EXPIRED';
  }
  // Erros de sintaxe JSON
  else if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    statusCode = 400;
    message = 'Formato JSON inválido na requisição.';
    code = 'INVALID_JSON';
  }
  // Erros de timeout
  else if (err.code === 'ETIMEDOUT' || err.message?.includes('timeout')) {
    statusCode = 504;
    message = 'A requisição demorou muito para ser processada. Tente novamente.';
    code = 'TIMEOUT';
  }

  // Resposta padronizada
  const response = {
    status: 'error',
    message,
    ...(code && { code }),
    ...(details && { details }),
  };

  // ✅ CORREÇÃO SEGURANÇA: Stack trace NUNCA é enviado em produção
  // Em desenvolvimento, adiciona stack trace apenas se não for ApiError
  if (process.env.NODE_ENV === 'development' && !(err instanceof ApiError)) {
    response.stack = err.stack;
  }
  // Garante que em produção nunca seja enviado, mesmo que NODE_ENV esteja mal configurado
  if (process.env.NODE_ENV === 'production') {
    // Remove qualquer stack trace que possa ter vindo de details ou outras fontes
    if (response.details && typeof response.details === 'object') {
      delete response.details.stack;
      if (response.details.stackTrace) delete response.details.stackTrace;
    }
  }

  res.status(statusCode).json(response);
};

module.exports = errorHandler;