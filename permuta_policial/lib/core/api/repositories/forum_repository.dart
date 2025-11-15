// /lib/core/api/repositories/forum_repository.dart

import '../api_client.dart';

class ForumRepository {
  final ApiClient _apiClient;

  ForumRepository(this._apiClient);

  // Categorias
  Future<List<dynamic>> getCategorias() async {
    final response = await _apiClient.get('/api/forum/categorias');
    return response as List<dynamic>;
  }

  // Tópicos
  Future<List<dynamic>> getTopicos({int? categoriaId, int? limit, int? offset}) async {
    // Permite que categoriaId seja nulo
    final queryParams = <String, String>{};
    
    // Só adiciona categoria_id se não for nulo
    if (categoriaId != null) {
      queryParams['categoria_id'] = categoriaId.toString();
    }
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();

    final queryString = queryParams.isEmpty
        ? '' // Se não houver parâmetros, não envia '?'
        : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
        
    final response = await _apiClient.get('/api/forum/topicos$queryString');
    return response as List<dynamic>;
  }

  Future<Map<String, dynamic>> getTopico(int topicoId) async {
    final response = await _apiClient.get('/api/forum/topicos/$topicoId');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTopico({
    required int categoriaId,
    required String titulo,
    required String conteudo,
  }) async {
    final payload = {
      'categoria_id': categoriaId,
      'titulo': titulo,
      'conteudo': conteudo,
    };
    final response = await _apiClient.post('/api/forum/topicos', payload);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTopico(int topicoId, {String? titulo, String? conteudo}) async {
    final payload = <String, dynamic>{};
    if (titulo != null) payload['titulo'] = titulo;
    if (conteudo != null) payload['conteudo'] = conteudo;
    
    final response = await _apiClient.put('/api/forum/topicos/$topicoId', payload);
    return response as Map<String, dynamic>;
  }

  Future<void> deleteTopico(int topicoId) async {
    await _apiClient.delete('/api/forum/topicos/$topicoId');
  }

  Future<List<dynamic>> searchTopicos(String searchTerm, {int? limit, int? offset}) async {
    final queryParams = <String, String>{'q': searchTerm};
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();
    
    final queryString = '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    final response = await _apiClient.get('/api/forum/topicos/search$queryString');
    return response as List<dynamic>;
  }

  // Respostas
  Future<List<dynamic>> getRespostas(int topicoId, {int? limit, int? offset}) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();
    
    final queryString = queryParams.isEmpty 
        ? '' 
        : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    
    final response = await _apiClient.get('/api/forum/topicos/$topicoId/respostas$queryString');
    return response as List<dynamic>;
  }

  Future<Map<String, dynamic>> createResposta(int topicoId, String conteudo, {int? respostaId}) async {
    final payload = <String, dynamic>{'conteudo': conteudo};
    if (respostaId != null) payload['resposta_id'] = respostaId;
    
    final response = await _apiClient.post('/api/forum/topicos/$topicoId/respostas', payload);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateResposta(int respostaId, String conteudo) async {
    final payload = {'conteudo': conteudo};
    final response = await _apiClient.put('/api/forum/respostas/$respostaId', payload);
    return response as Map<String, dynamic>;
  }

  Future<void> deleteResposta(int respostaId) async {
    await _apiClient.delete('/api/forum/respostas/$respostaId');
  }

  // Reações
  Future<Map<String, dynamic>> toggleReacao({
    required String tipo,
    int? topicoId,
    int? respostaId,
  }) async {
    final queryParams = <String, String>{};
    if (topicoId != null) queryParams['topicoId'] = topicoId.toString();
    if (respostaId != null) queryParams['respostaId'] = respostaId.toString();
    
    final queryString = '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    final payload = {'tipo': tipo};
    
    final response = await _apiClient.post('/api/forum/reacoes$queryString', payload);
    return response as Map<String, dynamic>;
  }

  Future<List<dynamic>> getReacoes({int? topicoId, int? respostaId}) async {
    final queryParams = <String, String>{};
    if (topicoId != null) queryParams['topicoId'] = topicoId.toString();
    if (respostaId != null) queryParams['respostaId'] = respostaId.toString();
    
    final queryString = '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    final response = await _apiClient.get('/api/forum/reacoes$queryString');
    return response as List<dynamic>;
  }

  // Moderação - Tópicos
  Future<Map<String, dynamic>> aprovarTopico(int topicoId) async {
    final response = await _apiClient.post('/api/forum/moderacao/topicos/$topicoId/aprovar', {});
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rejeitarTopico(int topicoId, String motivoRejeicao) async {
    final payload = {'motivo_rejeicao': motivoRejeicao};
    final response = await _apiClient.post('/api/forum/moderacao/topicos/$topicoId/rejeitar', payload);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> toggleFixarTopico(int topicoId) async {
    final response = await _apiClient.post('/api/forum/moderacao/topicos/$topicoId/fixar', {});
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> toggleBloquearTopico(int topicoId) async {
    final response = await _apiClient.post('/api/forum/moderacao/topicos/$topicoId/bloquear', {});
    return response as Map<String, dynamic>;
  }

  // Moderação - Respostas
  Future<Map<String, dynamic>> aprovarResposta(int respostaId) async {
    final response = await _apiClient.post('/api/forum/moderacao/respostas/$respostaId/aprovar', {});
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rejeitarResposta(int respostaId, String motivoRejeicao) async {
    final payload = {'motivo_rejeicao': motivoRejeicao};
    final response = await _apiClient.post('/api/forum/moderacao/respostas/$respostaId/rejeitar', payload);
    return response as Map<String, dynamic>;
  }

  // Listar itens pendentes
  Future<List<dynamic>> getTopicosPendentes({int? limit, int? offset}) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();
    
    final queryString = queryParams.isEmpty 
        ? '' 
        : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    
    final response = await _apiClient.get('/api/forum/moderacao/topicos/pendentes$queryString');
    return response as List<dynamic>;
  }

  Future<List<dynamic>> getRespostasPendentes({int? limit, int? offset}) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();
    
    final queryString = queryParams.isEmpty 
        ? '' 
        : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    
    final response = await _apiClient.get('/api/forum/moderacao/respostas/pendentes$queryString');
    return response as List<dynamic>;
  }
}

