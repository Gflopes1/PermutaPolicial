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
  final int? raioKm;
  final DateTime? criadoEm;
  final DateTime? renovadoEm;

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
    this.raioKm,
    this.criadoEm,
    this.renovadoEm,
  });

  factory Intencao.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

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
      raioKm: json['raio_km'] != null ? (json['raio_km'] as num).toInt() : null,
      criadoEm: parseDate(json['criado_em']),
      renovadoEm: parseDate(json['renovado_em']),
    );
  }
}
