// /lib/core/services/analytics_service.dart

import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../utils/device_info_utils.dart';

class AnalyticsService {
  final ApiClient _apiClient;
  String? _sessionId;
  DateTime? _sessionStart;
  final Map<String, DateTime> _pageViewStarts = {};

  AnalyticsService(this._apiClient) {
    _initSession();
  }

  void _initSession() {
    _sessionId = '${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
    _sessionStart = DateTime.now();
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(length, (index) => chars[(DateTime.now().millisecondsSinceEpoch + index) % chars.length]).join();
  }

  // Registra um evento de usuário
  Future<void> trackEvent(String eventoTipo, {Map<String, dynamic>? metadata}) async {
    try {
      await _apiClient.post('/api/analytics/evento', {
        'evento_tipo': eventoTipo,
        'metadata': metadata,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao registrar evento: $e');
      }
    }
  }

  // Registra uma falha/erro com causa
  Future<void> trackError(String errorType, {
    String? errorMessage,
    String? errorCode,
    int? statusCode,
    String? endpoint,
    String? method,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _apiClient.post('/api/analytics/evento', {
        'evento_tipo': 'error_occurred',
        'metadata': {
          'error_type': errorType,
          'error_message': errorMessage,
          'error_code': errorCode,
          'status_code': statusCode,
          'endpoint': endpoint,
          'method': method,
          'details': details,
          'causa': _extractCause(errorType, errorCode, errorMessage, details, statusCode),
        },
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao registrar falha: $e');
      }
    }
  }

  // Extrai a causa do erro baseado no tipo e código
  String _extractCause(String errorType, String? errorCode, String? errorMessage, Map<String, dynamic>? details, int? statusCode) {
    if (errorCode != null) {
      switch (errorCode) {
        case 'VALIDATION_ERROR':
          return 'Erro de validação de dados: ${details?['field'] ?? errorMessage ?? "Dados inválidos"}';
        case 'DATABASE_ERROR':
          return 'Erro no banco de dados: ${errorMessage ?? "Falha na operação"}';
        case 'INVALID_TOKEN':
        case 'TOKEN_EXPIRED':
          return 'Token de autenticação inválido ou expirado';
        case 'TIMEOUT':
        case 'CONNECTION_ERROR':
        case 'NO_CONNECTION':
          return 'Falha de conexão: ${errorMessage ?? "Sem conexão com o servidor"}';
        case 'HTTP_ERROR':
          return 'Erro HTTP: ${statusCode != null ? "Status $statusCode" : errorMessage ?? "Erro de comunicação"}';
        case 'INVALID_RESPONSE':
          return 'Resposta inválida do servidor: ${errorMessage ?? "Formato de dados incorreto"}';
        case 'SERVICE_UNAVAILABLE':
          return 'Serviço temporariamente indisponível';
        default:
          return errorMessage ?? 'Erro desconhecido';
      }
    }
    return errorMessage ?? 'Erro não especificado';
  }

  // Registra visualização de página
  Future<int?> trackPageView(String pagina) async {
    if (_sessionId == null) _initSession();

    try {
      final response = await _apiClient.post('/api/analytics/page-view', {
        'pagina': pagina,
        'sessao_id': _sessionId,
      });

      // ApiClient já extrai o 'data', então response já é o conteúdo de 'data'
      if (response != null && response['id'] != null) {
        final pageViewId = response['id'] as int;
        _pageViewStarts[pagina] = DateTime.now();
        return pageViewId;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao registrar page view: $e');
      }
    }
    return null;
  }

  // Atualiza tempo de permanência na página
  Future<void> updatePageViewDuration(String pagina, int pageViewId) async {
    if (!_pageViewStarts.containsKey(pagina)) return;

    final startTime = _pageViewStarts[pagina]!;
    final duration = DateTime.now().difference(startTime).inSeconds;
    _pageViewStarts.remove(pagina);

    try {
      await _apiClient.post('/api/analytics/tempo-permanencia', {
        'page_view_id': pageViewId,
        'tempo_segundos': duration,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao atualizar tempo de permanência: $e');
      }
    }
  }

  // Cria ou atualiza sessão
  Future<void> createOrUpdateSession({String? dispositivoTipo, String? navegador, String? sistemaOperacional}) async {
    if (_sessionId == null) _initSession();

    final detected = getDeviceInfo();

    try {
      await _apiClient.post('/api/analytics/sessao', {
        'sessao_id': _sessionId,
        'dispositivo_tipo': dispositivoTipo ?? detected.dispositivoTipo,
        'navegador': navegador ?? detected.navegador,
        'sistema_operacional': sistemaOperacional ?? detected.sistemaOperacional,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao criar/atualizar sessão: $e');
      }
    }
  }

  // Finaliza sessão
  Future<void> endSession() async {
    if (_sessionId == null || _sessionStart == null) return;

    final duration = DateTime.now().difference(_sessionStart!).inSeconds;

    try {
      await _apiClient.post('/api/analytics/sessao/finalizar', {
        'sessao_id': _sessionId,
        'duracao_segundos': duration,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao finalizar sessão: $e');
      }
    }

    _sessionId = null;
    _sessionStart = null;
  }
}

