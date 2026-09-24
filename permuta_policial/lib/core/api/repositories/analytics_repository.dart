// /lib/core/api/repositories/analytics_repository.dart

import '../api_client.dart';

class AnalyticsRepository {
  final ApiClient _apiClient;

  AnalyticsRepository(this._apiClient);

  // Busca estatísticas gerais
  Future<Map<String, dynamic>> getEstatisticasGerais({String? dataInicio, String? dataFim}) async {
    final queryParams = <String, String>{};
    if (dataInicio != null) queryParams['data_inicio'] = dataInicio;
    if (dataFim != null) queryParams['data_fim'] = dataFim;

    final queryString = queryParams.isEmpty 
        ? '' 
        : '?${Uri(queryParameters: queryParams).query}';
    
    final response = await _apiClient.get('/api/analytics/estatisticas$queryString');
    return response as Map<String, dynamic>;
  }

  // Busca estatísticas de page views
  Future<List<dynamic>> getPageViewsStats({String? dataInicio, String? dataFim}) async {
    final queryParams = <String, String>{};
    if (dataInicio != null) queryParams['data_inicio'] = dataInicio;
    if (dataFim != null) queryParams['data_fim'] = dataFim;

    final queryString = queryParams.isEmpty 
        ? '' 
        : '?${Uri(queryParameters: queryParams).query}';
    
    final response = await _apiClient.get('/api/analytics/page-views$queryString');
    return response as List<dynamic>;
  }

  // Busca eventos por tipo
  Future<List<dynamic>> getEventosPorTipo({String? dataInicio, String? dataFim}) async {
    final queryParams = <String, String>{};
    if (dataInicio != null) queryParams['data_inicio'] = dataInicio;
    if (dataFim != null) queryParams['data_fim'] = dataFim;

    final queryString = queryParams.isEmpty 
        ? '' 
        : '?${Uri(queryParameters: queryParams).query}';
    
    final response = await _apiClient.get('/api/analytics/eventos$queryString');
    return response as List<dynamic>;
  }

  // Busca estatísticas de sessões
  Future<Map<String, dynamic>> getSessoesStats({String? dataInicio, String? dataFim}) async {
    final queryParams = <String, String>{};
    if (dataInicio != null) queryParams['data_inicio'] = dataInicio;
    if (dataFim != null) queryParams['data_fim'] = dataFim;

    final queryString = queryParams.isEmpty 
        ? '' 
        : '?${Uri(queryParameters: queryParams).query}';
    
    final response = await _apiClient.get('/api/analytics/sessoes$queryString');
    return response as Map<String, dynamic>;
  }

  // Busca atividade por hora
  Future<List<dynamic>> getAtividadePorHora({String? dataInicio, String? dataFim}) async {
    final queryParams = <String, String>{};
    if (dataInicio != null) queryParams['data_inicio'] = dataInicio;
    if (dataFim != null) queryParams['data_fim'] = dataFim;

    final queryString = queryParams.isEmpty 
        ? '' 
        : '?${Uri(queryParameters: queryParams).query}';
    
    final response = await _apiClient.get('/api/analytics/atividade-hora$queryString');
    return response as List<dynamic>;
  }

  Future<List<dynamic>> getCrescimentoUsuarios({
    String? dataInicio,
    String? dataFim,
    String granularidade = 'dia',
    bool cumulativo = false,
    int? estadoId,
    int? forcaId,
  }) async {
    final queryParams = <String, String>{
      'granularidade': granularidade,
      if (cumulativo) 'cumulativo': 'true',
      if (dataInicio != null) 'data_inicio': dataInicio,
      if (dataFim != null) 'data_fim': dataFim,
      if (estadoId != null) 'estado_id': estadoId.toString(),
      if (forcaId != null) 'forca_id': forcaId.toString(),
    };
    final queryString = '?${Uri(queryParameters: queryParams).query}';
    final response = await _apiClient.get('/api/analytics/crescimento-usuarios$queryString');
    return response as List<dynamic>;
  }

  Future<List<dynamic>> getUsuariosPorEstado() async {
    final response = await _apiClient.get('/api/analytics/usuarios-por-estado');
    return response as List<dynamic>;
  }

  Future<List<dynamic>> getUsuariosPorForcaDetalhado() async {
    final response = await _apiClient.get('/api/analytics/usuarios-por-forca');
    return response as List<dynamic>;
  }

  Future<List<dynamic>> getContasAtivas({
    String? dataInicio,
    String? dataFim,
    String granularidade = 'dia',
  }) async {
    final queryParams = <String, String>{
      'granularidade': granularidade,
      if (dataInicio != null) 'data_inicio': dataInicio,
      if (dataFim != null) 'data_fim': dataFim,
    };
    final queryString = '?${Uri(queryParameters: queryParams).query}';
    final response = await _apiClient.get('/api/analytics/contas-ativas$queryString');
    return response as List<dynamic>;
  }

  Future<Map<String, dynamic>> getResumoAdmin({
    String? dataInicio,
    String? dataFim,
    String granularidade = 'dia',
    bool cumulativo = false,
  }) async {
    final queryParams = <String, String>{
      'granularidade': granularidade,
      if (cumulativo) 'cumulativo': 'true',
      if (dataInicio != null) 'data_inicio': dataInicio,
      if (dataFim != null) 'data_fim': dataFim,
    };
    final queryString = '?${Uri(queryParameters: queryParams).query}';
    final response = await _apiClient.get('/api/analytics/resumo$queryString');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMediaKitExport({String? dataInicio, String? dataFim}) async {
    final queryParams = <String, String>{};
    if (dataInicio != null) queryParams['data_inicio'] = dataInicio;
    if (dataFim != null) queryParams['data_fim'] = dataFim;
    final queryString = queryParams.isEmpty ? '' : '?${Uri(queryParameters: queryParams).query}';
    final response = await _apiClient.get('/api/analytics/media-kit$queryString');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getFunilPermuta() async {
    final response = await _apiClient.get('/api/analytics/permuta/funil');
    return response as Map<String, dynamic>;
  }

  Future<List<dynamic>> getDemandaPorMunicipio({int? forcaId, int? estadoId, int limit = 30}) async {
    final queryParams = <String, String>{'limit': limit.toString()};
    if (forcaId != null) queryParams['forca_id'] = forcaId.toString();
    if (estadoId != null) queryParams['estado_id'] = estadoId.toString();
    final queryString = Uri(queryParameters: queryParams).query;
    final response = await _apiClient.get('/api/analytics/permuta/demanda-municipios?$queryString');
    return response as List<dynamic>;
  }

  Future<List<dynamic>> getDemandaPorForca() async {
    final response = await _apiClient.get('/api/analytics/permuta/demanda-forcas');
    return response as List<dynamic>;
  }

  Future<Map<String, dynamic>> getEngajamentoPermuta({String? dataInicio, String? dataFim}) async {
    final queryParams = <String, String>{};
    if (dataInicio != null) queryParams['data_inicio'] = dataInicio;
    if (dataFim != null) queryParams['data_fim'] = dataFim;
    final queryString = queryParams.isEmpty ? '' : '?${Uri(queryParameters: queryParams).query}';
    final response = await _apiClient.get('/api/analytics/permuta/engajamento$queryString');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getHistoricoIntencoes({int limit = 20}) async {
    final response = await _apiClient.get('/api/analytics/permuta/historico-intencoes?limit=$limit');
    return response as Map<String, dynamic>;
  }
}

