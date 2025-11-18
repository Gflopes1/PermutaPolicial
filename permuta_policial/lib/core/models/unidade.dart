// /lib/core/models/unidade.dart

class Unidade {
  final int id;
  final String nome;
  final bool generica;

  Unidade({required this.id, required this.nome, required this.generica});

  factory Unidade.fromJson(Map<String, dynamic> json) {
    // Converte int (0/1) para bool
    bool genericaValue = false;
    if (json['generica'] != null) {
      if (json['generica'] is bool) {
        genericaValue = json['generica'] as bool;
      } else if (json['generica'] is int) {
        genericaValue = (json['generica'] as int) == 1;
      } else if (json['generica'] is String) {
        genericaValue = json['generica'] == '1' || json['generica'].toLowerCase() == 'true';
      }
    }
    
    return Unidade(
      id: json['id'],
      nome: json['nome'] ?? '',
      generica: genericaValue,
    );
  }
}