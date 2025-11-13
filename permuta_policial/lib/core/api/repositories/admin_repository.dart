// /lib/core/api/repositories/admin_repository.dart

import '../api_client.dart';

class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository(this._apiClient);

  Future<Map<String, dynamic>> getEstatisticas() async {
    return await _apiClient.get('/api/admin/estatisticas');
  }

  Future<List<Map<String, dynamic>>> getSugestoes() async {
    final data = await _apiClient.get('/api/admin/sugestoes');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> aprovarSugestao(int id) async {
    return await _apiClient.post('/api/admin/sugestoes/$id/aprovar', {});
  }

  Future<Map<String, dynamic>> rejeitarSugestao(int id) async {
    return await _apiClient.post('/api/admin/sugestoes/$id/rejeitar', {});
  }

  Future<List<Map<String, dynamic>>> getVerificacoes() async {
    final data = await _apiClient.get('/api/admin/verificacoes');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> verificarPolicial(int id) async {
    return await _apiClient.post('/api/admin/verificacoes/$id/verificar', {});
  }

  Future<Map<String, dynamic>> rejeitarPolicial(int id) async {
    return await _apiClient.post('/api/admin/verificacoes/$id/rejeitar', {});
  }

  Future<Map<String, dynamic>> getAllPoliciais({
    String? search,
    String? statusVerificacao,
    int? forcaId,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (statusVerificacao != null) {
      queryParams['status_verificacao'] = statusVerificacao;
    }
    if (forcaId != null) {
      queryParams['forca_id'] = forcaId.toString();
    }

    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return await _apiClient.get('/api/admin/policiais?$queryString');
  }

  Future<Map<String, dynamic>> updatePolicial(int id, Map<String, dynamic> data) async {
    return await _apiClient.put('/api/admin/policiais/$id', data);
  }
}

