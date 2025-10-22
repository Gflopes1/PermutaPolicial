// /lib/core/api/repositories/parceiros_repository.dart

import '../api_client.dart';
import '../../models/parceiro.dart';

class ParceirosRepository {
  final ApiClient _apiClient;

  ParceirosRepository(this._apiClient);

  /// Busca a configuração e a lista de parceiros da API.
  Future<Map<String, dynamic>> getParceirosConfig() async {
    final responseData = await _apiClient.get('/api/parceiros'); // Endpoint público que criaremos

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
}