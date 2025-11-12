// /lib/core/api/api_exception.dart

/// Códigos de erro padronizados da API
enum ApiErrorCode {
  // Erros de validação (400)
  validationError,
  invalidInput,
  
  // Erros de autenticação (401)
  unauthorized,
  invalidCredentials,
  tokenExpired,
  tokenInvalid,
  
  // Erros de autorização (403)
  forbidden,
  insufficientPermissions,
  
  // Erros de recurso não encontrado (404)
  notFound,
  resourceNotFound,
  
  // Erros de conflito (409)
  conflict,
  duplicateEntry,
  
  // Erros do servidor (500)
  internalError,
  databaseError,
  externalServiceError,
  
  // Erros de serviço indisponível (503)
  serviceUnavailable,
  
  // Erros de conexão
  connectionError,
  timeoutError,
  unknownError,
}

/// Classe de exceção customizada para erros da API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiErrorCode? errorCode;
  final Map<String, dynamic>? details;
  final String? originalError;

  ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.details,
    this.originalError,
  });

  /// Cria uma ApiException a partir de um código de erro do backend
  factory ApiException.fromErrorCode(
    String? code,
    String message,
    int? statusCode, {
    Map<String, dynamic>? details,
  }) {
    ApiErrorCode? errorCode;
    
    switch (code?.toUpperCase()) {
      case 'VALIDATION_ERROR':
      case 'INVALID_INPUT':
        errorCode = ApiErrorCode.validationError;
        break;
      case 'UNAUTHORIZED':
        errorCode = ApiErrorCode.unauthorized;
        break;
      case 'INVALID_CREDENTIALS':
        errorCode = ApiErrorCode.invalidCredentials;
        break;
      case 'TOKEN_EXPIRED':
        errorCode = ApiErrorCode.tokenExpired;
        break;
      case 'TOKEN_INVALID':
        errorCode = ApiErrorCode.tokenInvalid;
        break;
      case 'FORBIDDEN':
      case 'INSUFFICIENT_PERMISSIONS':
        errorCode = ApiErrorCode.forbidden;
        break;
      case 'NOT_FOUND':
      case 'RESOURCE_NOT_FOUND':
        errorCode = ApiErrorCode.notFound;
        break;
      case 'CONFLICT':
      case 'DUPLICATE_ENTRY':
        errorCode = ApiErrorCode.conflict;
        break;
      case 'DATABASE_ERROR':
        errorCode = ApiErrorCode.databaseError;
        break;
      case 'SERVICE_UNAVAILABLE':
        errorCode = ApiErrorCode.serviceUnavailable;
        break;
      case 'INTERNAL_ERROR':
      case 'EXTERNAL_SERVICE_ERROR':
        errorCode = ApiErrorCode.internalError;
        break;
      default:
        errorCode = _getErrorCodeFromStatusCode(statusCode);
    }
    
    return ApiException(
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
      details: details,
    );
  }

  /// Determina o código de erro baseado no status code
  static ApiErrorCode? _getErrorCodeFromStatusCode(int? statusCode) {
    if (statusCode == null) return ApiErrorCode.unknownError;
    
    switch (statusCode) {
      case 400:
        return ApiErrorCode.validationError;
      case 401:
        return ApiErrorCode.unauthorized;
      case 403:
        return ApiErrorCode.forbidden;
      case 404:
        return ApiErrorCode.notFound;
      case 409:
        return ApiErrorCode.conflict;
      case 500:
        return ApiErrorCode.internalError;
      case 503:
        return ApiErrorCode.serviceUnavailable;
      default:
        return ApiErrorCode.unknownError;
    }
  }

  /// Verifica se o erro é de autenticação
  bool get isAuthenticationError {
    return errorCode == ApiErrorCode.unauthorized ||
           errorCode == ApiErrorCode.invalidCredentials ||
           errorCode == ApiErrorCode.tokenExpired ||
           errorCode == ApiErrorCode.tokenInvalid ||
           statusCode == 401;
  }

  /// Verifica se o erro é de autorização
  bool get isAuthorizationError {
    return errorCode == ApiErrorCode.forbidden ||
           errorCode == ApiErrorCode.insufficientPermissions ||
           statusCode == 403;
  }

  /// Verifica se o erro é de validação
  bool get isValidationError {
    return errorCode == ApiErrorCode.validationError ||
           errorCode == ApiErrorCode.invalidInput ||
           statusCode == 400;
  }

  /// Verifica se o erro é de conexão
  bool get isConnectionError {
    return errorCode == ApiErrorCode.connectionError ||
           errorCode == ApiErrorCode.timeoutError ||
           errorCode == ApiErrorCode.serviceUnavailable;
  }

  /// Verifica se o erro é do servidor
  bool get isServerError {
    return errorCode == ApiErrorCode.internalError ||
           errorCode == ApiErrorCode.databaseError ||
           errorCode == ApiErrorCode.externalServiceError ||
           (statusCode != null && statusCode! >= 500);
  }

  @override
  String toString() {
    return 'ApiException: $message (Status Code: $statusCode, Error Code: $errorCode)';
  }
}