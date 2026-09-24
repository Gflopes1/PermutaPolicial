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

  Future<List<Map<String, dynamic>>> getVerificacoesOcr() async {
    final data = await _apiClient.get('/api/verificacao/ocr/pendentes');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> aprovarVerificacaoOcr(int id) async {
    return await _apiClient.post('/api/verificacao/ocr/pendentes/$id/aprovar', {});
  }

  Future<Map<String, dynamic>> rejeitarVerificacaoOcr(int id) async {
    return await _apiClient.post('/api/verificacao/ocr/pendentes/$id/rejeitar', {});
  }

  Future<Map<String, dynamic>> getAllPoliciais({
    String? search,
    String? statusVerificacao,
    int? forcaId,
    int limit = 20,
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

  Future<Map<String, dynamic>> getPolicialDetalhes(int id) async {
    return await _apiClient.get('/api/admin/policiais/$id/detalhes');
  }

  Future<Map<String, dynamic>> deletePolicial(int id) async {
    return await _apiClient.delete('/api/admin/policiais/$id');
  }

  Future<Map<String, dynamic>> sendBulkEmail({
    required String subject,
    required String body,
  }) async {
    return await _apiClient.post('/api/admin/email/broadcast', {
      'subject': subject,
      'body': body,
    });
  }

  Future<Map<String, dynamic>> getConfiguracoes() async {
    return await _apiClient.get('/api/admin/configuracoes');
  }

  Future<Map<String, dynamic>> updateConfiguracoes(Map<String, dynamic> data) async {
    return await _apiClient.put('/api/admin/configuracoes', data);
  }

  Future<Map<String, dynamic>> rebuildPermutasInteligentesGraph() async {
    return await _apiClient.post('/api/admin/permutas-inteligentes/rebuild-graph', {});
  }

  Future<Map<String, dynamic>> getPremiumUsers({
    String? search,
    String? status,
    String? provider,
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
    if (status != null) {
      queryParams['status'] = status;
    }
    if (provider != null) {
      queryParams['provider'] = provider;
    }

    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return await _apiClient.get('/api/admin/premium?$queryString');
  }

  Future<Map<String, dynamic>> getProblemaRelatos({
    String? status,
    int page = 1,
    int perPage = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final data = await _apiClient.get('/api/admin/problemas-relatos?$queryString');
    if (data is Map<String, dynamic>) return data;
    return {'relatos': data, 'total': 0};
  }

  Future<Map<String, dynamic>> atualizarProblemaRelatoStatus(
    int id, {
    required String status,
    String? resolucao,
  }) async {
    return await _apiClient.put('/api/admin/problemas-relatos/$id/status', {
      'status': status,
      if (resolucao != null) 'resolucao': resolucao,
    });
  }

  Future<List<Map<String, dynamic>>> getPermutasConcluidas() async {
    final data = await _apiClient.get('/api/admin/permutas-concluidas');
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getPerformanceLogs({
    int limit = 100,
    String? module,
  }) async {
    final queryParams = <String, String>{'limit': limit.toString()};
    if (module != null && module.isNotEmpty) {
      queryParams['module'] = module;
    }
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final data = await _apiClient.get('/api/admin/performance-logs?$queryString');
    if (data is List) {
      return List<Map<String, dynamic>>.from(
        data.map((e) => Map<String, dynamic>.from(e as Map)),
      );
    }
    return [];
  }

  Future<Map<String, dynamic>> getActivityLogs({
    int limit = 100,
    int offset = 0,
    String? tipo,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (tipo != null && tipo.isNotEmpty) {
      queryParams['tipo'] = tipo;
    }
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final data = await _apiClient.get('/api/admin/activity-logs?$queryString');
    if (data is Map<String, dynamic>) return data;
    return {'logs': [], 'total': 0};
  }
}

