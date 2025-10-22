// /lib/core/models/estado.dart

class Estado {
  final int id;
  final String nome;
  final String sigla;

  Estado({required this.id, required this.nome, required this.sigla});

  factory Estado.fromJson(Map<String, dynamic> json) {
    return Estado(
      id: json['id'],
      nome: json['nome'] ?? '',
      sigla: json['sigla'] ?? '',
    );
  }
}