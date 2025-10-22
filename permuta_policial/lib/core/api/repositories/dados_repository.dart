// /lib/core/api/repositories/dados_repository.dart

import '../api_client.dart';
import '../../models/forca_policial.dart';
import '../../models/estado.dart';
import '../../models/municipio.dart';
import '../../models/unidade.dart';
import '../../models/posto_graduacao.dart';

class DadosRepository {
  final ApiClient _apiClient;

  DadosRepository(this._apiClient);

  /// Busca a lista de todas as forças policiais.
  Future<List<ForcaPolicial>> getForcas() async {
    final List<dynamic> responseData = await _apiClient.get('/api/dados/forcas');
    return responseData.map((json) => ForcaPolicial.fromJson(json)).toList();
  }

  /// Busca a lista de todos os estados.
  Future<List<Estado>> getEstados() async {
    final List<dynamic> responseData = await _apiClient.get('/api/dados/estados');
    return responseData.map((json) => Estado.fromJson(json)).toList();
  }

  /// Busca os municípios de um estado específico.
  Future<List<Municipio>> getMunicipiosPorEstado(int estadoId) async {
    final List<dynamic> responseData = await _apiClient.get('/api/dados/municipios/$estadoId');
    return responseData.map((json) => Municipio.fromJson(json)).toList();
  }

  /// Busca as unidades de um município e força específicos.
  Future<List<Unidade>> getUnidades({required int municipioId, required int forcaId}) async {
    final endpoint = '/api/dados/unidades?municipio_id=$municipioId&forca_id=$forcaId';
    final List<dynamic> responseData = await _apiClient.get(endpoint);
    return responseData.map((json) => Unidade.fromJson(json)).toList();
  }
  
  /// Busca os postos/graduações de um tipo de força específico.
  Future<List<PostoGraduacao>> getPostosPorForca(String tipoPermuta) async {
    final List<dynamic> responseData = await _apiClient.get('/api/dados/postos/$tipoPermuta');
    return responseData.map((json) => PostoGraduacao.fromJson(json)).toList();
  }

  /// Envia a sugestão de uma nova unidade.
  Future<Map<String, dynamic>> sugerirUnidade({
    required String nomeSugerido,
    required int municipioId,
    required int forcaId,
  }) async {
    final payload = {
      'nome_sugerido': nomeSugerido,
      'municipio_id': municipioId,
      'forca_id': forcaId,
    };
    final responseData = await _apiClient.post('/api/dados/unidades/sugerir', payload);
    return responseData;
  }
}