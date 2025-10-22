// /lib/core/api/repositories/mapa_repository.dart

import '../api_client.dart';
import '../../models/ponto_mapa.dart';
import '../../models/detalhe_municipio.dart';

class MapaRepository {
  final ApiClient _apiClient;

  MapaRepository(this._apiClient);

  /// Busca os pontos de dados para exibir no mapa, aplicando filtros opcionais.
  Future<List<PontoMapa>> getMapData({
    String tipo = 'saindo',
    int? estadoId,
    int? forcaId,
  }) async {
    // Monta o mapa de query parameters
    final queryParams = <String, String>{
      'tipo': tipo,
    };
    if (estadoId != null) {
      queryParams['estado_id'] = estadoId.toString();
    }
    if (forcaId != null) {
      queryParams['forca_id'] = forcaId.toString();
    }

    // Constrói a query string (ex: "?tipo=saindo&estado_id=5")
    final queryString = Uri(queryParameters: queryParams).query;
    final endpoint = '/api/mapa/dados?$queryString';

    final responseData = await _apiClient.get(endpoint);
    
    // O backend retorna um objeto {"pontos": [...]}, então pegamos a lista de "pontos"
    final List<dynamic> pontosData = responseData['pontos'] ?? [];
    
    return pontosData.map((json) => PontoMapa.fromJson(json)).toList();
  }

  /// Busca a lista de detalhes dos policiais em um município específico.
  Future<List<DetalheMunicipio>> getMunicipioDetails({
    required int municipioId,
    required String tipo,
    int? forcaId,
  }) async {
    final queryParams = <String, String>{
      'id': municipioId.toString(),
      'tipo': tipo,
    };
    if (forcaId != null) {
      queryParams['forca_id'] = forcaId.toString();
    }

    final queryString = Uri(queryParameters: queryParams).query;
    final endpoint = '/api/mapa/detalhes-municipio?$queryString';

    final List<dynamic> responseData = await _apiClient.get(endpoint);
    
    return responseData.map((json) => DetalheMunicipio.fromJson(json)).toList();
  }
}