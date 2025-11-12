// /lib/core/api/repositories/admin_repository.dart

import '../api_client.dart';
import '../../models/parceiro.dart';

class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository(this._apiClient);

  // Estatísticas
  Future<Map<String, dynamic>> getEstatisticas() async {
    final responseData = await _apiClient.get('/api/admin/estatisticas');
    return responseData as Map<String, dynamic>;
  }

  // Usuários/Policiais
  Future<Map<String, dynamic>> getAllPoliciais({
    int page = 1,
    int limit = 50,
    String search = '',
  }) async {
    final queryParams = <String>[];
    queryParams.add('page=${page.toString()}');
    queryParams.add('limit=${limit.toString()}');
    if (search.isNotEmpty) {
      queryParams.add('search=${Uri.encodeComponent(search)}');
    }
    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final responseData = await _apiClient.get('/api/admin/policiais$queryString');
    return responseData as Map<String, dynamic>;
  }

  // Verificações
  Future<List<dynamic>> getVerificacoes() async {
    final responseData = await _apiClient.get('/api/admin/verificacoes');
    return responseData as List<dynamic>;
  }

  Future<void> verificarPolicial(int policialId) async {
    await _apiClient.post('/api/admin/verificacoes/$policialId/verificar', {});
  }

  Future<void> rejeitarPolicial(int policialId) async {
    await _apiClient.post('/api/admin/verificacoes/$policialId/rejeitar', {});
  }

  // Sugestões
  Future<List<dynamic>> getSugestoes() async {
    final responseData = await _apiClient.get('/api/admin/sugestoes');
    return responseData as List<dynamic>;
  }

  Future<void> aprovarSugestao(int sugestaoId) async {
    await _apiClient.post('/api/admin/sugestoes/$sugestaoId/aprovar', {});
  }

  Future<void> rejeitarSugestao(int sugestaoId) async {
    await _apiClient.post('/api/admin/sugestoes/$sugestaoId/rejeitar', {});
  }

  // Parceiros
  Future<List<Parceiro>> getAllParceiros() async {
    final responseData = await _apiClient.get('/api/admin/parceiros');
    final List<dynamic> parceirosJson = responseData as List<dynamic>;
    return parceirosJson.map((json) => Parceiro.fromJson(json)).toList();
  }

  Future<Parceiro> createParceiro(Map<String, dynamic> parceiro) async {
    final responseData = await _apiClient.post(
      '/api/admin/parceiros',
      parceiro,
    );
    return Parceiro.fromJson(responseData);
  }

  Future<void> updateParceiro(int id, Map<String, dynamic> parceiro) async {
    await _apiClient.put('/api/admin/parceiros/$id', parceiro);
  }

  Future<void> deleteParceiro(int id) async {
    // Usando POST como fallback já que ApiClient não tem DELETE
    // O backend aceita DELETE, mas para compatibilidade usamos POST
    await _apiClient.post('/api/admin/parceiros/$id/delete', {});
  }

  Future<Map<String, dynamic>> getParceirosConfig() async {
    final responseData = await _apiClient.get('/api/admin/parceiros/config');
    return responseData as Map<String, dynamic>;
  }

  Future<void> updateParceirosConfig(bool exibirCard) async {
    await _apiClient.put(
      '/api/admin/parceiros/config',
      {'exibir_card': exibirCard},
    );
  }
}

