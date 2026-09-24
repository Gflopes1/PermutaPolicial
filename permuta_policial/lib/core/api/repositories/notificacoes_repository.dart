// /lib/core/api/repositories/notificacoes_repository.dart

import '../api_client.dart';
import '../../models/notificacao.dart';

class NotificacoesRepository {
  final ApiClient _apiClient;

  NotificacoesRepository(this._apiClient);

  Future<List<Notificacao>> getNotificacoes() async {
    final response = await _apiClient.get('/api/notificacoes');
    if (response is List) {
      return response.map((item) => Notificacao.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<int> countNaoLidas() async {
    final response = await _apiClient.get('/api/notificacoes/count');
    return response['count'] ?? 0;
  }

  Future<Map<String, dynamic>> criarSolicitacaoContato(int destinatarioId, {String? origem, String? tipoPermuta}) async {
    final body = <String, dynamic>{
      'destinatario_id': destinatarioId,
    };
    if (origem != null) {
      body['origem'] = origem;
    }
    if (tipoPermuta != null) {
      body['tipo_permuta'] = tipoPermuta;
    }
    final response = await _apiClient.post('/api/notificacoes/solicitar-contato', body);
    // ✅ Retorna a resposta completa (pode conter already_exists: true)
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {};
  }

  Future<void> responderSolicitacaoContato(int notificacaoId, bool aceitar) async {
    await _apiClient.post('/api/notificacoes/$notificacaoId/responder', {
      'aceitar': aceitar,
    });
  }

  Future<void> marcarComoLida(int id) async {
    await _apiClient.put('/api/notificacoes/$id/lida', {});
  }

  Future<void> marcarTodasComoLidas() async {
    await _apiClient.put('/api/notificacoes/marcar-todas-lidas', {});
  }

  Future<void> delete(int id) async {
    await _apiClient.delete('/api/notificacoes/$id');
  }
}

