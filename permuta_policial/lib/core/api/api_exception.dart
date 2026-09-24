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
          // Se houver detalhes de validação, mostra o primeiro erro específico
          if (details != null && details!.isNotEmpty) {
            final firstError = details!.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              return firstError.first.toString();
            } else if (firstError is String) {
              return firstError;
            }
          }
          return 'Por favor, verifique os dados informados.';
        case 'DATABASE_ERROR':
          return 'Erro ao processar sua solicitação. Tente novamente.';
        case 'SERVICE_UNAVAILABLE':
          return 'Serviço temporariamente indisponível. Tente novamente em alguns instantes.';
        case 'INVALID_CREDENTIALS':
          return 'Email ou senha incorretos. Verifique suas credenciais e tente novamente.';
        case 'INVALID_TOKEN':
        case 'TOKEN_EXPIRED':
          return 'Sua sessão expirou. Por favor, faça login novamente.';
        case 'TIMEOUT':
        case 'CONNECTION_ERROR':
        case 'NO_CONNECTION':
          return 'Erro de conexão. Verifique sua internet e tente novamente.';
        case 'HTTP_ERROR':
          return 'Erro de comunicação com o servidor. Tente novamente.';
        case 'INVALID_RESPONSE':
          return 'Resposta inválida do servidor. Tente novamente.';
        case 'UPLOAD_ERROR':
          return 'Erro ao fazer upload. Verifique sua conexão e tente novamente.';
        case 'PHOTO_UPLOAD_UNAVAILABLE':
          return 'Upload de fotos indisponível no momento. Crie o ponto sem foto ou tente mais tarde.';
        case 'EMAIL_ALREADY_EXISTS':
          return 'Este e-mail já está cadastrado. Tente fazer login ou recuperar sua senha.';
        case 'ID_FUNCIONAL_ALREADY_EXISTS':
          return 'Este ID Funcional/Matrícula já está cadastrado nesta Força Policial. Verifique os dados e tente novamente.';
        case 'DUPLICATE_ENTRY':
          return 'Já existe um registro com estes dados. Verifique as informações e tente novamente.';
        case 'DUPLICATE':
          return 'Contato já solicitado.';
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