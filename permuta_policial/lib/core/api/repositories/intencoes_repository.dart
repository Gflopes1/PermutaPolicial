// /lib/core/api/repositories/intencoes_repository.dart

import 'package:permuta_policial/core/api/api_client.dart';
import 'package:permuta_policial/core/models/intencao.dart';

class IntencoesRepository {
  final ApiClient _apiClient;

  IntencoesRepository(this._apiClient);

  /// Busca a lista de intenções do usuário logado.
  Future<List<Intencao>> getMyIntentions() async {
    // A API retorna uma lista de objetos diretamente na chave "data".
    final List<dynamic> responseData = await _apiClient.get('/api/intencoes/me');
    
    // Mapeia a lista de JSONs para uma lista de objetos Intencao.
    return responseData.map((json) => Intencao.fromJson(json)).toList();
  }

  /// Atualiza a lista de intenções do usuário.
  Future<Map<String, dynamic>> updateMyIntentions(List<Map<String, dynamic>> intencoes) async {
    final payload = {'intencoes': intencoes};
    final responseData = await _apiClient.put('/api/intencoes/me', payload);
    return responseData;
  }

  /// Exclui todas as intenções do usuário.
  Future<Map<String, dynamic>> deleteMyIntentions() async {
    final responseData = await _apiClient.delete('/api/intencoes/me');
    return responseData;
  }
}