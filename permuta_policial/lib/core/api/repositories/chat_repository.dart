// /lib/core/api/repositories/chat_repository.dart

import '../api_client.dart';

class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository(this._apiClient);

  // Busca todas as conversas do usuário
  Future<List<dynamic>> getConversas() async {
    final response = await _apiClient.get('/api/chat/conversas');
    return response as List<dynamic>;
  }

  // Busca informações de uma conversa específica
  Future<Map<String, dynamic>> getConversa(int conversaId) async {
    final response = await _apiClient.get('/api/chat/conversas/$conversaId');
    return response as Map<String, dynamic>;
  }

  // Busca mensagens de uma conversa
  Future<List<dynamic>> getMensagens(int conversaId, {int? limit, int? offset}) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();
    
    final queryString = queryParams.isEmpty 
        ? '' 
        : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    
    final response = await _apiClient.get('/api/chat/conversas/$conversaId/mensagens$queryString');
    return response as List<dynamic>;
  }

  // Cria uma nova mensagem
  Future<Map<String, dynamic>> createMensagem(int conversaId, String mensagem) async {
    final payload = {'mensagem': mensagem};
    final response = await _apiClient.post('/api/chat/conversas/$conversaId/mensagens', payload);
    return response as Map<String, dynamic>;
  }

  // Inicia uma nova conversa com outro usuário
  Future<Map<String, dynamic>> iniciarConversa(int usuarioId) async {
    final payload = {'usuarioId': usuarioId};
    final response = await _apiClient.post('/api/chat/conversas', payload);
    return response as Map<String, dynamic>;
  }

  // Marca mensagens como lidas
  Future<void> marcarComoLidas(int conversaId) async {
    await _apiClient.put('/api/chat/conversas/$conversaId/lidas', {});
  }

  // Conta mensagens não lidas
  Future<int> getMensagensNaoLidas() async {
    final response = await _apiClient.get('/api/chat/mensagens/nao-lidas');
    return (response as Map<String, dynamic>)['total'] as int;
  }
}




