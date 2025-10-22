// /lib/core/models/municipio.dart

class Municipio {
  final int id;
  final String nome;

  Municipio({required this.id, required this.nome});

  factory Municipio.fromJson(Map<String, dynamic> json) {
    return Municipio(
      id: json['id'],
      nome: json['nome'] ?? '',
    );
  }
}