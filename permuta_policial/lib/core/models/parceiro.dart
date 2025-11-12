// /lib/core/models/parceiro.dart

class Parceiro {
  final int id;
  final String imagemUrl;
  final String? linkUrl;
  final int ordem;
  final bool ativo;
  final DateTime? criadoEm;

  Parceiro({
    required this.id,
    required this.imagemUrl,
    this.linkUrl,
    this.ordem = 0,
    this.ativo = true,
    this.criadoEm,
  });

  factory Parceiro.fromJson(Map<String, dynamic> json) {
    return Parceiro(
      id: json['id'] ?? 0,
      imagemUrl: json['imagem_url'] ?? '',
      linkUrl: json['link_url'],
      ordem: json['ordem'] ?? 0,
      ativo: (json['ativo'] as int? ?? 1) == 1,
      criadoEm: json['criado_em'] != null
          ? DateTime.parse(json['criado_em'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imagem_url': imagemUrl,
      'link_url': linkUrl,
      'ordem': ordem,
      'ativo': ativo,
    };
  }
}