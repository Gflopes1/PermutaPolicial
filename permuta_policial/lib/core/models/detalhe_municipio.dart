// /lib/core/models/detalhe_municipio.dart

class DetalheMunicipio {
  final int policialId;
  final String policialNome;
  final String? qso;
  final String forcaSigla;
  final String? unidadeNome;
  final String? municipioAtual;
  final String? estadoAtual;
  final String? municipioDesejado;
  final String? estadoDesejado;
  final String? destinosDesejados;

  DetalheMunicipio({
    required this.policialId,
    required this.policialNome,
    this.qso,
    required this.forcaSigla,
    this.unidadeNome,
    this.municipioAtual,
    this.estadoAtual,
    this.municipioDesejado,
    this.estadoDesejado,
    this.destinosDesejados,
  });

  factory DetalheMunicipio.fromJson(Map<String, dynamic> json) {
    return DetalheMunicipio(
      policialId: json['policial_id'] ?? 0,
      policialNome: json['policial_nome'] ?? 'Nome não informado',
      qso: json['qso'],
      forcaSigla: json['forca_sigla'] ?? 'N/A',
      unidadeNome: json['unidade_nome'],
      municipioAtual: json['municipio_atual'],
      estadoAtual: json['estado_atual'],
      municipioDesejado: json['municipio_desejado'],
      estadoDesejado: json['estado_desejado'],
      destinosDesejados: json['destinos_desejados'],
    );
  }
}