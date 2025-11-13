// /lib/core/api/api_exception.dart

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? details;

  ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  /// Retorna uma mensagem amigável para o usuário
  String get userMessage {
    if (code != null) {
      switch (code) {
        case 'VALIDATION_ERROR':
          return 'Por favor, verifique os dados informados.';
        case 'DATABASE_ERROR':
          return 'Erro ao processar sua solicitação. Tente novamente.';
        case 'SERVICE_UNAVAILABLE':
          return 'Serviço temporariamente indisponível. Tente novamente em alguns instantes.';
        case 'INVALID_TOKEN':
        case 'TOKEN_EXPIRED':
          return 'Sua sessão expirou. Por favor, faça login novamente.';
        case 'TIMEOUT':
          return 'A requisição demorou muito. Verifique sua conexão e tente novamente.';
        default:
          return message;
      }
    }
    return message;
  }

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode${code != null ? ', Code: $code' : ''})';
  }
}