import 'dart:convert';

class Simulado {
  final int? id;
  final int userId;
  final String? titulo;
  final Map<String, dynamic> config;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime? createdAt;

  Simulado({
    this.id,
    required this.userId,
    this.titulo,
    required this.config,
    this.startedAt,
    this.finishedAt,
    this.createdAt,
  });

  factory Simulado.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> config = {};
    if (json['config'] != null) {
      if (json['config'] is Map) {
        config = Map<String, dynamic>.from(json['config']);
      } else if (json['config'] is String) {
        try {
          config = jsonDecode(json['config']);
        } catch (e) {
          config = {};
        }
      }
    }

    return Simulado(
      id: json['id'],
      userId: json['user_id'],
      titulo: json['titulo'],
      config: config,
      startedAt: json['started_at'] != null 
        ? DateTime.parse(json['started_at']) 
        : null,
      finishedAt: json['finished_at'] != null 
        ? DateTime.parse(json['finished_at']) 
        : null,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'titulo': titulo,
      'config': jsonEncode(config),
      'started_at': startedAt?.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
    };
  }
}

class SimuladoResult {
  final Simulado simulado;
  final List<QuestionAttempt> attempts;
  final int total;
  final int correct;
  final double accuracy;
  final int totalTime;

  SimuladoResult({
    required this.simulado,
    required this.attempts,
    required this.total,
    required this.correct,
    required this.accuracy,
    required this.totalTime,
  });

  factory SimuladoResult.fromJson(Map<String, dynamic> json) {
    return SimuladoResult(
      simulado: Simulado.fromJson(json['simulado']),
      attempts: (json['attempts'] as List?)
          ?.map((a) => QuestionAttempt.fromJson(a))
          .toList() ?? [],
      total: json['total'] ?? 0,
      correct: json['correct'] ?? 0,
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      totalTime: json['total_time'] ?? 0,
    );
  }
}

class QuestionAttempt {
  final int? id;
  final int questionId;
  final String answerGiven;
  final bool correct;
  final int timeSpentSeconds;
  final String? pergunta;
  final List<String>? alternativas;
  final String? respostaCorreta;
  final String? explicacao;
  final String? assunto;
  final String? tipo;

  QuestionAttempt({
    this.id,
    required this.questionId,
    required this.answerGiven,
    required this.correct,
    required this.timeSpentSeconds,
    this.pergunta,
    this.alternativas,
    this.respostaCorreta,
    this.explicacao,
    this.assunto,
    this.tipo,
  });

  factory QuestionAttempt.fromJson(Map<String, dynamic> json) {
    List<String>? alternativas;
    if (json['alternativas'] != null) {
      if (json['alternativas'] is List) {
        alternativas = List<String>.from(json['alternativas']);
      } else if (json['alternativas'] is String) {
        try {
          final parsed = jsonDecode(json['alternativas']);
          alternativas = List<String>.from(parsed);
        } catch (e) {
          alternativas = null;
        }
      }
    }

    return QuestionAttempt(
      id: json['id'],
      questionId: json['question_id'],
      answerGiven: json['answer_given'] ?? '',
      correct: json['correct'] ?? false,
      timeSpentSeconds: json['time_spent_seconds'] ?? 0,
      pergunta: json['pergunta'],
      alternativas: alternativas,
      respostaCorreta: json['resposta_correta'],
      explicacao: json['explicacao'],
      assunto: json['assunto'],
      tipo: json['tipo'],
    );
  }
}


