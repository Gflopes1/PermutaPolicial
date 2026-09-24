// /lib/core/utils/error_handler.dart

import 'package:flutter/foundation.dart';
import '../api/api_exception.dart';
import '../services/analytics_service.dart';

/// Classe utilitária para tratamento padronizado de erros
class ErrorHandler {
  /// Extrai uma mensagem amigável de qualquer erro
  static String getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.userMessage;
    }
    
    if (error is Exception) {
      final errorString = error.toString().toLowerCase();
      
      // Detecta erros específicos na mensagem
      if (errorString.contains('id') && (errorString.contains('cadastrado') || errorString.contains('duplicate') || errorString.contains('already exists'))) {
        return 'Este ID Funcional/Matrícula já está cadastrado nesta Força Policial. Verifique os dados e tente novamente.';
      }
      
      // Detecta erros comuns mesmo sem ApiException
      if (errorString.contains('timeout') || errorString.contains('timed out')) {
        return 'A requisição demorou muito. Verifique sua conexão e tente novamente.';
      }
      
      if (errorString.contains('socket') || errorString.contains('connection')) {
        return 'Erro de conexão. Verifique sua internet e tente novamente.';
      }
      
      if (errorString.contains('format') || errorString.contains('json')) {
        return 'Erro ao processar resposta do servidor. Tente novamente.';
      }
    }
    
    // Mensagem genérica como fallback
    return 'Ocorreu um erro inesperado. Tente novamente ou entre em contato com o suporte.';
  }

  /// Verifica se o erro é relacionado a conexão (permite retry)
  static bool isConnectionError(dynamic error) {
    if (error is ApiException) {
      return error.code == 'NO_CONNECTION' || 
             error.code == 'CONNECTION_ERROR' || 
             error.code == 'TIMEOUT' ||
             error.code == 'SERVICE_UNAVAILABLE';
    }
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
           errorString.contains('socket') ||
           errorString.contains('connection') ||
           errorString.contains('network');
  }

  /// Verifica se o erro requer novo login
  static bool requiresReauth(dynamic error) {
    if (error is ApiException) {
      return error.code == 'INVALID_TOKEN' || 
             error.code == 'TOKEN_EXPIRED' ||
             error.statusCode == 401;
    }
    return false;
  }

  /// Registra um erro no analytics com causa
  static Future<void> trackError(
    AnalyticsService analyticsService,
    dynamic error, {
    String? endpoint,
    String? method,
  }) async {
    try {
      String errorType = 'unknown';
      String? errorMessage;
      String? errorCode;
      int? statusCode;
      Map<String, dynamic>? details;

      if (error is ApiException) {
        errorType = 'api_error';
        errorMessage = error.message;
        errorCode = error.code;
        statusCode = error.statusCode;
        details = error.details;
      } else if (error is Exception) {
        errorType = 'exception';
        errorMessage = error.toString();
      } else {
        errorType = 'unknown';
        errorMessage = error.toString();
      }

      await analyticsService.trackError(
        errorType,
        errorMessage: errorMessage,
        errorCode: errorCode,
        statusCode: statusCode,
        endpoint: endpoint,
        method: method,
        details: details,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao registrar falha no analytics: $e');
      }
    }
  }
}

