// /lib/core/api/repositories/questions_repository.dart

import '../api_client.dart';
import '../../models/question.dart';
import '../../models/simulado.dart';
import '../../models/comment.dart';

class QuestionsRepository {
  final ApiClient _apiClient;

  QuestionsRepository(this._apiClient);

  // Busca opções para criar simulado
  Future<Map<String, dynamic>> getCreateOptions() async {
    return await _apiClient.get('/api/simulado/create-options');
  }

  // Lista questões com filtros
  Future<Map<String, dynamic>> getQuestions({
    String? assunto,
    String? subassunto,
    String? tipo,
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (assunto != null && assunto.isNotEmpty) queryParams['assunto'] = assunto;
    if (subassunto != null && subassunto.isNotEmpty) queryParams['subassunto'] = subassunto;
    if (tipo != null && tipo.isNotEmpty) queryParams['tipo'] = tipo;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final queryString = queryParams.isEmpty
        ? ''
        : '?${queryParams.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}';
    
    return await _apiClient.get('/api/questions$queryString');
  }

  // Busca questão por ID
  Future<Question> getQuestionById(int id) async {
    final response = await _apiClient.get('/api/questions/$id');
    return Question.fromJson(response as Map<String, dynamic>);
  }

  // Cria um simulado
  Future<Simulado> createSimulado({
    required String type,
    int? questionCount,
    Map<String, int>? subjects,
    List<String>? subassuntos,
    String? tipo,
    String? titulo,
    int timerSeconds = 3600,
  }) async {
    final body = {
      'type': type,
      'timerSeconds': timerSeconds,
    };
    if (questionCount != null) body['questionCount'] = questionCount;
    if (subjects != null) body['subjects'] = subjects;
    if (subassuntos != null && subassuntos.isNotEmpty) body['subassuntos'] = subassuntos;
    if (tipo != null && tipo.isNotEmpty) body['tipo'] = tipo;
    if (titulo != null) body['titulo'] = titulo;

    final response = await _apiClient.post('/api/simulado', body);
    return Simulado.fromJson(response as Map<String, dynamic>);
  }

  // Inicia um simulado
  Future<Map<String, dynamic>> startSimulado(int simuladoId) async {
    return await _apiClient.post('/api/simulado/$simuladoId/start', {});
  }

  // Busca questão atual do simulado
  Future<Map<String, dynamic>> getCurrentQuestion(int simuladoId, int ordem) async {
    final queryString = '?ordem=${Uri.encodeComponent(ordem.toString())}';
    return await _apiClient.get('/api/simulado/$simuladoId/question$queryString');
  }

  // Submete resposta do simulado
  Future<Map<String, dynamic>> submitAnswer({
    required int simuladoId,
    required int questionId,
    required int ordem,
    required String answerGiven,
    required int timeSpentSeconds,
    required int serverStartTime,
  }) async {
    return await _apiClient.post(
      '/api/simulado/$simuladoId/answer',
      {
        'question_id': questionId,
        'ordem': ordem,
        'answer_given': answerGiven,
        'time_spent_seconds': timeSpentSeconds,
        'server_start_time': serverStartTime,
      },
    );
  }

  // Busca resultado do simulado
  Future<SimuladoResult> getResult(int simuladoId) async {
    final response = await _apiClient.get('/api/simulado/$simuladoId/result');
    return SimuladoResult.fromJson(response as Map<String, dynamic>);
  }

  // Lista comentários de uma questão
  Future<Map<String, dynamic>> getComments(int questionId, {int page = 1, int perPage = 20}) async {
    final queryString = '?page=${Uri.encodeComponent(page.toString())}&per_page=${Uri.encodeComponent(perPage.toString())}';
    return await _apiClient.get('/api/comments/questions/$questionId/comments$queryString');
  }

  // Cria um comentário
  Future<Comment> createComment(int questionId, String content, {int? parentId}) async {
    final body = {
      'content': content,
      if (parentId != null) 'parent_id': parentId,
    };
    final response = await _apiClient.post('/api/comments/questions/$questionId/comments', body);
    return Comment.fromJson(response as Map<String, dynamic>);
  }

  // Toggle like em um comentário
  Future<Map<String, dynamic>> toggleLike(int commentId) async {
    return await _apiClient.post('/api/comments/$commentId/like', {});
  }

  // Lista respostas de um comentário
  Future<List<Comment>> getReplies(int commentId, {int page = 1, int perPage = 10}) async {
    final queryString = '?page=${Uri.encodeComponent(page.toString())}&per_page=${Uri.encodeComponent(perPage.toString())}';
    final response = await _apiClient.get('/api/comments/$commentId/replies$queryString');
    final data = response as List<dynamic>;
    return data.map((c) => Comment.fromJson(c as Map<String, dynamic>)).toList();
  }

  // Modo Prática - Buscar próxima questão não respondida
  Future<Question> getNextPracticeQuestion({
    List<String>? subjects,
    List<String>? subassuntos,
    String? tipo,
  }) async {
    final queryParams = <String, String>{};
    if (subjects != null && subjects.isNotEmpty) {
      queryParams['subjects'] = subjects.join(',');
    }
    if (subassuntos != null && subassuntos.isNotEmpty) {
      queryParams['subassuntos'] = subassuntos.join(',');
    }
    if (tipo != null && tipo.isNotEmpty) {
      queryParams['tipo'] = tipo;
    }
    final queryString = queryParams.isEmpty
        ? ''
        : '?${queryParams.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}';
    final response = await _apiClient.get('/api/questions/practice/next$queryString');
    return Question.fromJson(response as Map<String, dynamic>);
  }

  // Modo Prática - Salvar resposta
  Future<Map<String, dynamic>> savePracticeAnswer({
    required int questionId,
    required String answerGiven,
    int timeSpentSeconds = 0,
  }) async {
    return await _apiClient.post('/api/questions/practice/answer', {
      'question_id': questionId,
      'answer_given': answerGiven,
      'time_spent_seconds': timeSpentSeconds,
    });
  }

  // Modo Prática - Histórico
  Future<Map<String, dynamic>> getPracticeHistory({
    int page = 1,
    int perPage = 20,
    String? assunto,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (assunto != null) queryParams['assunto'] = assunto;
    final queryString = '?${queryParams.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}';
    return await _apiClient.get('/api/questions/practice/history$queryString');
  }

  // Modo Prática - Resetar questão
  Future<void> resetPracticeAnswer(int questionId) async {
    await _apiClient.delete('/api/questions/practice/reset/$questionId');
  }

  // Admin - Listar questões pendentes
  Future<Map<String, dynamic>> getPendingQuestions({
    int page = 1,
    int perPage = 20,
    String? assunto,
    String? subassunto,
    String? tipo,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (assunto != null && assunto.isNotEmpty) {
      queryParams['assunto'] = assunto;
    }
    if (subassunto != null && subassunto.isNotEmpty) {
      queryParams['subassunto'] = subassunto;
    }
    if (tipo != null && tipo.isNotEmpty) {
      queryParams['tipo'] = tipo;
    }
    final queryString = '?${queryParams.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}';
    return await _apiClient.get('/api/questions/admin/pending$queryString');
  }

  // Buscar todos os assuntos
  Future<List<String>> getAllAssuntos() async {
    final data = await _apiClient.get('/api/questions/assuntos');
    return List<String>.from(data);
  }

  // Buscar subassuntos por assunto
  Future<List<String>> getSubassuntosByAssunto(String assunto) async {
    final data = await _apiClient.get('/api/questions/subassuntos?assunto=${Uri.encodeComponent(assunto)}');
    return List<String>.from(data);
  }

  // Admin - Aprovar questão
  Future<Question> approveQuestion(int questionId) async {
    final response = await _apiClient.put('/api/questions/admin/$questionId/approve', {});
    return Question.fromJson(response as Map<String, dynamic>);
  }

  // Admin - Rejeitar questão
  Future<Question> rejectQuestion(int questionId) async {
    final response = await _apiClient.put('/api/questions/admin/$questionId/reject', {});
    return Question.fromJson(response as Map<String, dynamic>);
  }
}

