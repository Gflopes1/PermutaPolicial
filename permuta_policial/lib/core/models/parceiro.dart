// /lib/core/models/parceiro.dart

class Parceiro {
  final int id;
  final String imagemUrl;
  final String? linkUrl;

  Parceiro({
    required this.id,
    required this.imagemUrl,
    this.linkUrl,
  });

  factory Parceiro.fromJson(Map<String, dynamic> json) {
    return Parceiro(
      id: json['id'] ?? 0,
      imagemUrl: json['imagem_url'] ?? '',
      linkUrl: json['link_url'],
    );
  }
}