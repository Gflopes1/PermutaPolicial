// /lib/core/utils/error_message_helper.dart

import '../api/api_exception.dart';

/// Helper para gerar mensagens de erro amigáveis para o usuário
class ErrorMessageHelper {
  /// Retorna uma mensagem amigável baseada no tipo de erro
  static String getFriendlyMessage(ApiException exception) {
    // Mensagens específicas baseadas no código de erro
    if (exception.errorCode != null) {
      switch (exception.errorCode!) {
        case ApiErrorCode.unauthorized:
        case ApiErrorCode.invalidCredentials:
          return 'Credenciais inválidas. Verifique seu email e senha.';
        
        case ApiErrorCode.tokenExpired:
        case ApiErrorCode.tokenInvalid:
          return 'Sua sessão expirou. Por favor, faça login novamente.';
        
        case ApiErrorCode.forbidden:
        case ApiErrorCode.insufficientPermissions:
          return 'Você não tem permissão para realizar esta ação.';
        
        case ApiErrorCode.notFound:
        case ApiErrorCode.resourceNotFound:
          return 'O recurso solicitado não foi encontrado.';
        
        case ApiErrorCode.validationError:
        case ApiErrorCode.invalidInput:
          return _getValidationErrorMessage(exception);
        
        case ApiErrorCode.conflict:
        case ApiErrorCode.duplicateEntry:
          return 'Os dados informados já existem no sistema.';
        
        case ApiErrorCode.connectionError:
          return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
        
        case ApiErrorCode.timeoutError:
          return 'Tempo de conexão esgotado. Verifique sua internet e tente novamente.';
        
        case ApiErrorCode.serviceUnavailable:
          return 'Serviço temporariamente indisponível. Tente novamente em alguns instantes.';
        
        case ApiErrorCode.databaseError:
          return 'Erro ao processar dados. Tente novamente mais tarde.';
        
        case ApiErrorCode.internalError:
        case ApiErrorCode.externalServiceError:
          return 'Ocorreu um erro no servidor. Nossa equipe foi notificada. Tente novamente mais tarde.';
        
        case ApiErrorCode.unknownError:
        default:
          return exception.message;
      }
    }
    
    // Fallback para mensagens baseadas no status code
    if (exception.statusCode != null) {
      switch (exception.statusCode) {
        case 400:
          return 'Dados inválidos. Verifique as informações e tente novamente.';
        case 401:
          return 'Você precisa estar logado para realizar esta ação.';
        case 403:
          return 'Você não tem permissão para realizar esta ação.';
        case 404:
          return 'O recurso solicitado não foi encontrado.';
        case 409:
          return 'Os dados informados já existem no sistema.';
        case 500:
          return 'Erro no servidor. Tente novamente mais tarde.';
        case 503:
          return 'Serviço temporariamente indisponível. Tente novamente em alguns instantes.';
        default:
          return exception.message;
      }
    }
    
    // Retorna a mensagem original se não houver código específico
    return exception.message;
  }

  /// Extrai mensagens de validação dos detalhes do erro
  static String _getValidationErrorMessage(ApiException exception) {
    if (exception.details != null && exception.details!['validation'] != null) {
      final validationErrors = exception.details!['validation'] as List?;
      if (validationErrors != null && validationErrors.isNotEmpty) {
        final firstError = validationErrors[0] as Map<String, dynamic>?;
        if (firstError != null && firstError['message'] != null) {
          return firstError['message'] as String;
        }
      }
    }
    
    return 'Dados inválidos. Verifique as informações e tente novamente.';
  }

  /// Retorna um título apropriado para o tipo de erro
  static String getErrorTitle(ApiException exception) {
    if (exception.isAuthenticationError) {
      return 'Erro de Autenticação';
    } else if (exception.isAuthorizationError) {
      return 'Acesso Negado';
    } else if (exception.isValidationError) {
      return 'Dados Inválidos';
    } else if (exception.isConnectionError) {
      return 'Problema de Conexão';
    } else if (exception.isServerError) {
      return 'Erro no Servidor';
    } else {
      return 'Erro';
    }
  }

  /// Verifica se o erro permite retry
  static bool canRetry(ApiException exception) {
    return exception.isConnectionError ||
           exception.isServerError ||
           exception.errorCode == ApiErrorCode.serviceUnavailable ||
           exception.errorCode == ApiErrorCode.timeoutError;
  }

  /// Retorna uma mensagem de ação sugerida
  static String? getSuggestedAction(ApiException exception) {
    if (exception.isAuthenticationError) {
      return 'Faça login novamente';
    } else if (exception.isConnectionError) {
      return 'Verifique sua conexão e tente novamente';
    } else if (exception.isServerError) {
      return 'Tente novamente em alguns instantes';
    } else if (exception.isValidationError) {
      return 'Verifique os dados e tente novamente';
    }
    return null;
  }
}

