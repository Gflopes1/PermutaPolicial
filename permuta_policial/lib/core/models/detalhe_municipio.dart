// /lib/core/models/detalhe_municipio.dart

class DetalheMunicipio {
  final String policialNome;
  final String forcaSigla;
  final String unidadeNome;

  DetalheMunicipio({
    required this.policialNome,
    required this.forcaSigla,
    required this.unidadeNome,
  });

  factory DetalheMunicipio.fromJson(Map<String, dynamic> json) {
    return DetalheMunicipio(
      policialNome: json['policial_nome'] ?? 'Nome não informado',
      forcaSigla: json['forca_sigla'] ?? 'N/A',
      unidadeNome: json['unidade_nome'] ?? 'Unidade não informada',
    );
  }
}