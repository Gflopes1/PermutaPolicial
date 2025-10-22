// /lib/core/models/unidade.dart

class Unidade {
  final int id;
  final String nome;
  final bool generica;

  Unidade({required this.id, required this.nome, required this.generica});

  factory Unidade.fromJson(Map<String, dynamic> json) {
    return Unidade(
      id: json['id'],
      nome: json['nome'] ?? '',
      generica: json['generica'] ?? false,
    );
  }
}