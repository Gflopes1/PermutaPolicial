// /src/core/utils/ApiError.js

/**
 * Códigos de erro padronizados da API
 */
const ErrorCodes = {
  // Erros de validação (400)
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  INVALID_INPUT: 'INVALID_INPUT',
  
  // Erros de autenticação (401)
  UNAUTHORIZED: 'UNAUTHORIZED',
  INVALID_CREDENTIALS: 'INVALID_CREDENTIALS',
  TOKEN_EXPIRED: 'TOKEN_EXPIRED',
  TOKEN_INVALID: 'TOKEN_INVALID',
  
  // Erros de autorização (403)
  FORBIDDEN: 'FORBIDDEN',
  INSUFFICIENT_PERMISSIONS: 'INSUFFICIENT_PERMISSIONS',
  
  // Erros de recurso não encontrado (404)
  NOT_FOUND: 'NOT_FOUND',
  RESOURCE_NOT_FOUND: 'RESOURCE_NOT_FOUND',
  
  // Erros de conflito (409)
  CONFLICT: 'CONFLICT',
  DUPLICATE_ENTRY: 'DUPLICATE_ENTRY',
  
  // Erros do servidor (500)
  INTERNAL_ERROR: 'INTERNAL_ERROR',
  DATABASE_ERROR: 'DATABASE_ERROR',
  EXTERNAL_SERVICE_ERROR: 'EXTERNAL_SERVICE_ERROR',
  
  // Erros de serviço indisponível (503)
  SERVICE_UNAVAILABLE: 'SERVICE_UNAVAILABLE',
};

/**
 * Classe de erro customizada para a API
 */
class ApiError extends Error {
  constructor(statusCode, message, errorCode = null, details = null) {
    super(message);
    this.name = 'ApiError';
    this.statusCode = statusCode;
    this.errorCode = errorCode || this._getDefaultErrorCode(statusCode);
    this.details = details;
    this.timestamp = new Date().toISOString();
    
    // Mantém o stack trace para debug
    Error.captureStackTrace(this, this.constructor);
  }

  /**
   * Retorna o código de erro padrão baseado no status code
   */
  _getDefaultErrorCode(statusCode) {
    const codeMap = {
      400: ErrorCodes.VALIDATION_ERROR,
      401: ErrorCodes.UNAUTHORIZED,
      403: ErrorCodes.FORBIDDEN,
      404: ErrorCodes.NOT_FOUND,
      409: ErrorCodes.CONFLICT,
      500: ErrorCodes.INTERNAL_ERROR,
      503: ErrorCodes.SERVICE_UNAVAILABLE,
    };
    return codeMap[statusCode] || ErrorCodes.INTERNAL_ERROR;
  }

  /**
   * Converte o erro para formato JSON para resposta da API
   */
  toJSON() {
    return {
      status: 'error',
      error: {
        code: this.errorCode,
        message: this.message,
        statusCode: this.statusCode,
        timestamp: this.timestamp,
        ...(this.details && { details: this.details }),
      },
    };
  }

  /**
   * Métodos estáticos para criar erros comuns
   */
  static badRequest(message, details = null) {
    return new ApiError(400, message, ErrorCodes.VALIDATION_ERROR, details);
  }

  static unauthorized(message = 'Não autorizado') {
    return new ApiError(401, message, ErrorCodes.UNAUTHORIZED);
  }

  static invalidCredentials(message = 'Credenciais inválidas') {
    return new ApiError(401, message, ErrorCodes.INVALID_CREDENTIALS);
  }

  static forbidden(message = 'Acesso negado') {
    return new ApiError(403, message, ErrorCodes.FORBIDDEN);
  }

  static notFound(message = 'Recurso não encontrado', resource = null) {
    return new ApiError(404, message, ErrorCodes.NOT_FOUND, resource ? { resource } : null);
  }

  static conflict(message = 'Conflito de dados', details = null) {
    return new ApiError(409, message, ErrorCodes.CONFLICT, details);
  }

  static internalError(message = 'Erro interno do servidor', details = null) {
    return new ApiError(500, message, ErrorCodes.INTERNAL_ERROR, details);
  }

  static databaseError(message = 'Erro no banco de dados', details = null) {
    return new ApiError(500, message, ErrorCodes.DATABASE_ERROR, details);
  }

  static serviceUnavailable(message = 'Serviço temporariamente indisponível') {
    return new ApiError(503, message, ErrorCodes.SERVICE_UNAVAILABLE);
  }
}

module.exports = ApiError;
module.exports.ErrorCodes = ErrorCodes;