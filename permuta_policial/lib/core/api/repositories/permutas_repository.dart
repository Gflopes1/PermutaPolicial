// /lib/core/api/repositories/permutas_repository.dart

import 'package:permuta_policial/core/api/api_client.dart';
import 'package:permuta_policial/core/models/match_results.dart';

class PermutasRepository {
  final ApiClient _apiClient;

  PermutasRepository(this._apiClient);

  /// Busca os resultados completos de matches para o usuário logado.
  /// O ApiClient lida com erros, e o modelo FullMatchResults lida com o parsing do JSON.
  Future<FullMatchResults> getMatches() async {
    // O apiClient já retorna o conteúdo da chave "data" da sua API.
    final responseData = await _apiClient.get('/api/permutas/matches');
    
    // Transforma o Map<String, dynamic> em um objeto FullMatchResults.
    return FullMatchResults.fromJson(responseData);
  }
}