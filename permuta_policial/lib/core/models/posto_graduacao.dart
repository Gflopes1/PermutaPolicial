// /lib/core/models/posto_graduacao.dart

class PostoGraduacao {
  final int id;
  final String nome;

  PostoGraduacao({required this.id, required this.nome});

  factory PostoGraduacao.fromJson(Map<String, dynamic> json) {
    return PostoGraduacao(
      id: json['id'],
      nome: json['nome'] ?? 'Não informado',
    );
  }
}