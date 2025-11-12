// /lib/core/models/detalhe_municipio.dart

class DetalheMunicipio {
  final String policialNome;
  final String forcaSigla;
  final String unidadeNome;
  final String? qso;

  DetalheMunicipio({
    required this.policialNome,
    required this.forcaSigla,
    required this.unidadeNome,
    this.qso,
  });

  factory DetalheMunicipio.fromJson(Map<String, dynamic> json) {
    return DetalheMunicipio(
      policialNome: json['policial_nome'] ?? 'Nome não informado',
      forcaSigla: json['forca_sigla'] ?? 'N/A',
      unidadeNome: json['unidade_nome'] ?? 'Unidade não informada',
      qso: json['qso'],
    );
  }
}