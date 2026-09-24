// /lib/core/utils/app_logger.dart
// Logger condicional — só emite com `--dart-define=ENV=dev`

import 'package:flutter/foundation.dart';

/// Logger centralizado — só emite com `--dart-define=ENV=dev`
class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  /// Logs só com build `--dart-define=ENV=dev`
  static bool get isDevLoggingEnabled {
    const env = String.fromEnvironment('ENV', defaultValue: '');
    return env == 'dev';
  }

  bool get isDevelopment => isDevLoggingEnabled;

  /// Log de informação (apenas com ENV=dev)
  void info(String message, [Map<String, dynamic>? data]) {
    if (!isDevelopment) return;
    debugPrint('ℹ️ [INFO] $message${data != null ? ' | Data: $data' : ''}');
  }

  /// Log de debug (apenas com ENV=dev)
  void debug(String message, [Map<String, dynamic>? data]) {
    if (!isDevelopment) return;
    debugPrint('🐛 [DEBUG] $message${data != null ? ' | Data: $data' : ''}');
  }

  /// Log de aviso (apenas com ENV=dev)
  void warn(String message, [Map<String, dynamic>? data]) {
    if (!isDevelopment) return;
    debugPrint('⚠️ [WARN] $message${data != null ? ' | Data: $data' : ''}');
  }

  /// Log genérico (apenas com ENV=dev)
  void log(String message, [Map<String, dynamic>? data]) {
    if (!isDevelopment) return;
    debugPrint('[LOG] $message${data != null ? ' | Data: $data' : ''}');
  }

  /// Log de erro (sempre loga mensagem resumida)
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('❌ [ERROR] $message');
    if (isDevelopment && error != null) {
      debugPrint('   Error: $error');
    }
    if (isDevelopment && stackTrace != null) {
      debugPrint('   StackTrace: $stackTrace');
    }
  }

  /// Log crítico (sempre loga, mesmo em produção)
  void critical(String message, [Object? error]) {
    debugPrint('🚨 [CRITICAL] $message');
    if (error != null) {
      debugPrint('   Error: $error');
    }
  }

  /// Log de sucesso (apenas com ENV=dev)
  void success(String message, [Map<String, dynamic>? data]) {
    if (!isDevelopment) return;
    debugPrint('✅ [SUCCESS] $message${data != null ? ' | Data: $data' : ''}');
  }
}

/// Instância global do logger para uso fácil
final appLogger = AppLogger.instance;
