// /lib/core/models/parceiro.dart

class Parceiro {
  final int id;
  final String imagemUrl;
  final String? linkUrl;
  final int ordemExibicao;
  final bool ativo;

  Parceiro({
    required this.id,
    required this.imagemUrl,
    this.linkUrl,
    this.ordemExibicao = 0,
    this.ativo = true,
  });

  factory Parceiro.fromJson(Map<String, dynamic> json) {
    return Parceiro(
      id: json['id'] ?? 0,
      imagemUrl: json['imagem_url'] ?? '',
      linkUrl: json['link_url'],
      ordemExibicao: json['ordem_exibicao'] ?? 0,
      ativo: json['ativo'] == 1 || json['ativo'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagem_url': imagemUrl,
      'link_url': linkUrl,
      'ordem_exibicao': ordemExibicao,
      'ativo': ativo ? 1 : 0,
    };
  }
}