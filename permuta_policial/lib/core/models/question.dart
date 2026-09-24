import 'dart:convert';

class Question {
  final int? id;
  final String pergunta;
  final List<String> alternativas;
  final String respostaCorreta;
  final String? explicacao;
  final String assunto;
  final String? subassunto;
  final String tipo;
  final String? origem;
  final DateTime? createdAt;

  Question({
    this.id,
    required this.pergunta,
    required this.alternativas,
    required this.respostaCorreta,
    this.explicacao,
    required this.assunto,
    this.subassunto,
    required this.tipo,
    this.origem,
    this.createdAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    List<String> alternativas = [];
    if (json['alternativas'] != null) {
      if (json['alternativas'] is List) {
        alternativas = List<String>.from(json['alternativas']);
      } else if (json['alternativas'] is String) {
        final altString = json['alternativas'] as String;
        // Se está truncado (termina com '...'), não tenta fazer parse
        if (altString.endsWith('...')) {
          // Alternativas truncadas - retorna lista vazia ou mensagem
          alternativas = ['[Alternativas truncadas - carregue a questão completa para ver]'];
        } else {
          try {
            final parsed = jsonDecode(altString);
            alternativas = List<String>.from(parsed);
          } catch (e) {
            alternativas = [];
          }
        }
      }
    }

    return Question(
      id: json['id'],
      pergunta: json['pergunta'] ?? '',
      alternativas: alternativas,
      respostaCorreta: json['resposta_correta'] ?? '',
      explicacao: json['explicacao'],
      assunto: json['assunto'] ?? '',
      subassunto: json['subassunto'],
      tipo: json['tipo'] ?? 'mc',
      origem: json['origem'],
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pergunta': pergunta,
      'alternativas': alternativas,
      'resposta_correta': respostaCorreta,
      'explicacao': explicacao,
      'assunto': assunto,
      'subassunto': subassunto,
      'tipo': tipo,
      'origem': origem,
    };
  }
}

