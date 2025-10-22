// /lib/core/models/intencao.dart

class Intencao {
  final int id;
  final int prioridade;
  final String tipoIntencao;
  final int? estadoId;
  final int? municipioId;
  final int? unidadeId;
  final String? estadoSigla;
  final String? municipioNome;
  final String? unidadeNome;

  Intencao({
    required this.id,
    required this.prioridade,
    required this.tipoIntencao,
    this.estadoId,
    this.municipioId,
    this.unidadeId,
    this.estadoSigla,
    this.municipioNome,
    this.unidadeNome,
  });

  factory Intencao.fromJson(Map<String, dynamic> json) {
    return Intencao(
      id: json['id'],
      prioridade: json['prioridade'],
      tipoIntencao: json['tipo_intencao'],
      estadoId: json['estado_id'],
      municipioId: json['municipio_id'],
      unidadeId: json['unidade_id'],
      estadoSigla: json['estado_sigla'],
      municipioNome: json['municipio_nome'],
      unidadeNome: json['unidade_nome'],
    );
  }
}