// /lib/core/utils/retry_helper.dart

import 'dart:async';
import 'error_handler.dart';

/// Helper para retry automático de operações que podem falhar por problemas de rede
class RetryHelper {
  /// Executa uma operação com retry automático em caso de erro de conexão
  /// 
  /// [operation] - Função assíncrona a ser executada
  /// [maxRetries] - Número máximo de tentativas (padrão: 3)
  /// [initialDelay] - Delay inicial entre tentativas (padrão: 2 segundos)
  /// [maxDelay] - Delay máximo entre tentativas (padrão: 10 segundos)
  /// [exponentialBackoff] - Se true, usa backoff exponencial (padrão: true)
  /// 
  /// Retorna o resultado da operação ou lança a última exceção
  static Future<T> retryOnConnectionError<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 2),
    Duration maxDelay = const Duration(seconds: 10),
    bool exponentialBackoff = true,
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        // Só faz retry se for erro de conexão
        if (!ErrorHandler.isConnectionError(e) || attempt >= maxRetries - 1) {
          rethrow;
        }

        attempt++;
        
        // Calcula o delay para a próxima tentativa
        Duration delay;
        if (exponentialBackoff) {
          final exponentialDelay = Duration(
            milliseconds: (initialDelay.inMilliseconds * (1 << (attempt - 1))).clamp(
              0,
              maxDelay.inMilliseconds,
            ),
          );
          delay = exponentialDelay;
        } else {
          delay = initialDelay;
        }

        // Aguarda antes da próxima tentativa
        await Future.delayed(delay);
      }
    }

    // Se chegou aqui, todas as tentativas falharam
    throw lastException ?? Exception('Falha após $maxRetries tentativas');
  }

  /// Executa uma operação com retry simples (sem backoff exponencial)
  static Future<T> retrySimple<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) {
    return retryOnConnectionError<T>(
      operation: operation,
      maxRetries: maxRetries,
      initialDelay: delay,
      exponentialBackoff: false,
    );
  }
}

