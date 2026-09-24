import 'package:flutter/foundation.dart';
import '../../../core/api/repositories/questions_repository.dart';
import '../../../core/models/question.dart';
import '../../../core/models/simulado.dart';
import '../../../core/models/comment.dart';

class QuestionsProvider with ChangeNotifier {
  final QuestionsRepository _questionsRepository;

  QuestionsProvider(this._questionsRepository);

  List<Question> _questions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<Map<String, dynamic>?> getCreateOptions() async {
    try {
      return await _questionsRepository.getCreateOptions();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> loadQuestions({
    String? assunto,
    String? subassunto,
    String? tipo,
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _questionsRepository.getQuestions(
        assunto: assunto,
        subassunto: subassunto,
        tipo: tipo,
        page: page,
        perPage: perPage,
        search: search,
      );
      final data = response['data'] as List;
      _questions = data.map((q) => Question.fromJson(q)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Question?> getQuestionById(int id) async {
    try {
      return await _questionsRepository.getQuestionById(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Simulado?> createSimulado({
    required String type,
    int? questionCount,
    Map<String, int>? subjects,
    List<String>? subassuntos,
    String? tipo,
    String? titulo,
    int timerSeconds = 3600,
  }) async {
    try {
      return await _questionsRepository.createSimulado(
        type: type,
        questionCount: questionCount,
        subjects: subjects,
        subassuntos: subassuntos,
        tipo: tipo,
        titulo: titulo,
        timerSeconds: timerSeconds,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> startSimulado(int simuladoId) async {
    try {
      final response = await _questionsRepository.startSimulado(simuladoId);
      return response;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCurrentQuestion(int simuladoId, int ordem) async {
    try {
      final response = await _questionsRepository.getCurrentQuestion(simuladoId, ordem);
      return response;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> submitAnswer({
    required int simuladoId,
    required int questionId,
    required int ordem,
    required String answerGiven,
    required int timeSpentSeconds,
    required int serverStartTime,
  }) async {
    try {
      final response = await _questionsRepository.submitAnswer(
        simuladoId: simuladoId,
        questionId: questionId,
        ordem: ordem,
        answerGiven: answerGiven,
        timeSpentSeconds: timeSpentSeconds,
        serverStartTime: serverStartTime,
      );
      return response;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<SimuladoResult?> getResult(int simuladoId) async {
    try {
      return await _questionsRepository.getResult(simuladoId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<List<Comment>> getComments(int questionId, {int page = 1, int perPage = 20}) async {
    try {
      final response = await _questionsRepository.getComments(questionId, page: page, perPage: perPage);
      final data = response['data'] as List;
      return data.map((c) => Comment.fromJson(c)).toList();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<Comment?> createComment(int questionId, String content, {int? parentId}) async {
    try {
      return await _questionsRepository.createComment(questionId, content, parentId: parentId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> toggleLike(int commentId) async {
    try {
      final response = await _questionsRepository.toggleLike(commentId);
      return response['liked'] ?? false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<Comment>> getReplies(int commentId, {int page = 1, int perPage = 10}) async {
    try {
      return await _questionsRepository.getReplies(commentId, page: page, perPage: perPage);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Modo Prática
  Future<Question?> getNextPracticeQuestion({
    List<String>? subjects,
    List<String>? subassuntos,
    String? tipo,
  }) async {
    try {
      return await _questionsRepository.getNextPracticeQuestion(
        subjects: subjects,
        subassuntos: subassuntos,
        tipo: tipo,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> savePracticeAnswer({
    required int questionId,
    required String answerGiven,
    int timeSpentSeconds = 0,
  }) async {
    try {
      return await _questionsRepository.savePracticeAnswer(
        questionId: questionId,
        answerGiven: answerGiven,
        timeSpentSeconds: timeSpentSeconds,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPracticeHistory({
    int page = 1,
    int perPage = 5, // Carrega 5 inicialmente
    String? assunto,
  }) async {
    try {
      return await _questionsRepository.getPracticeHistory(
        page: page,
        perPage: perPage,
        assunto: assunto,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> resetPracticeAnswer(int questionId) async {
    try {
      await _questionsRepository.resetPracticeAnswer(questionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Admin
  Future<Map<String, dynamic>?> getPendingQuestions({
    int page = 1,
    int perPage = 5, // Carrega 5 inicialmente
    String? assunto,
    String? subassunto,
    String? tipo,
  }) async {
    try {
      return await _questionsRepository.getPendingQuestions(
        page: page,
        perPage: perPage,
        assunto: assunto,
        subassunto: subassunto,
        tipo: tipo,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<List<String>> getAllAssuntos() async {
    try {
      return await _questionsRepository.getAllAssuntos();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<List<String>> getSubassuntosByAssunto(String assunto) async {
    try {
      return await _questionsRepository.getSubassuntosByAssunto(assunto);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<bool> approveQuestion(int questionId) async {
    try {
      await _questionsRepository.approveQuestion(questionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectQuestion(int questionId) async {
    try {
      await _questionsRepository.rejectQuestion(questionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

}

