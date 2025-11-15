// /lib/core/api/repositories/parceiros_repository.dart

import '../api_client.dart';

class ParceirosRepository {
  final ApiClient _apiClient;

  ParceirosRepository(this._apiClient);

  /// Obtém a configuração dos parceiros (público)
  Future<Map<String, dynamic>> getParceirosConfig() async {
    final response = await _apiClient.get('/api/parceiros');
    return response;
  }

  /// Obtém todos os parceiros (admin)
  Future<List<dynamic>> getAll() async {
    final response = await _apiClient.get('/api/parceiros/admin');
    return response as List<dynamic>;
  }

  /// Cria um novo parceiro
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/api/parceiros/admin', data,);
    return response;
  }

  /// Atualiza um parceiro existente
  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('/api/parceiros/admin/$id', data);
    return response;
  }

  /// Deleta um parceiro
  Future<void> delete(int id) async {
    await _apiClient.delete('/api/parceiros/admin/$id');
  }

  /// Atualiza a configuração de exibição do card
  Future<void> updateConfig(bool exibirCard) async {
    await _apiClient.post('/api/parceiros/admin/config', {'exibir_card': exibirCard});
  }
}