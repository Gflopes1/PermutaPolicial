// /lib/core/api/repositories/configuracoes_repository.dart

import '../api_client.dart';

class ConfiguracoesRepository {
  final ApiClient _apiClient;

  ConfiguracoesRepository(this._apiClient);

  Future<Map<String, dynamic>> getAppConfig() async {
    final responseData = await _apiClient.get('/api/configuracoes/app');
    return responseData as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getNotaAtualizacao() async {
    final responseData = await _apiClient.get('/api/configuracoes/nota-atualizacao');
    return responseData as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getApoio() async {
    final responseData = await _apiClient.get('/api/configuracoes/apoio', requireAuth: false);
    return responseData as Map<String, dynamic>;
  }
}

