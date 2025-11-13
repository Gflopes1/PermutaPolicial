// /lib/core/api/repositories/parceiros_repository.dart

import '../api_client.dart';
import '../../models/parceiro.dart';

class ParceirosRepository {
  final ApiClient _apiClient;

  ParceirosRepository(this._apiClient);

  /// Busca a configuração e a lista de parceiros da API (público).
  Future<Map<String, dynamic>> getParceirosConfig() async {
    final responseData = await _apiClient.get('/api/parceiros');

    final bool exibirCard = responseData['exibir_card'] ?? false;
    final List<dynamic> parceirosJson = responseData['parceiros'] ?? [];

    final List<Parceiro> parceirosList = parceirosJson
        .map((json) => Parceiro.fromJson(json))
        .toList();

    return {
      'exibir_card': exibirCard,
      'parceiros': parceirosList,
    };
  }

  // Métodos de admin
  Future<List<Parceiro>> getAll() async {
    final data = await _apiClient.get('/api/parceiros/admin');
    return (data as List).map((json) => Parceiro.fromJson(json)).toList();
  }

  Future<Parceiro> getById(int id) async {
    final data = await _apiClient.get('/api/parceiros/admin/$id');
    return Parceiro.fromJson(data);
  }

  Future<Parceiro> create(Map<String, dynamic> parceiroData) async {
    final data = await _apiClient.post('/api/parceiros/admin', parceiroData);
    return Parceiro.fromJson(data);
  }

  Future<Parceiro> update(int id, Map<String, dynamic> parceiroData) async {
    final data = await _apiClient.put('/api/parceiros/admin/$id', parceiroData);
    return Parceiro.fromJson(data);
  }

  Future<void> delete(int id) async {
    await _apiClient.delete('/api/parceiros/admin/$id');
  }

  Future<Map<String, dynamic>> updateConfig(bool exibirCard) async {
    return await _apiClient.put('/api/parceiros/admin/config', {'exibir_card': exibirCard});
  }
}
