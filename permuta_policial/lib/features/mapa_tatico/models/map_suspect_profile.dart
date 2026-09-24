class MapSuspectProfile {
  final int pointId;
  final String? apelido;
  final String? caracteristicasFisicas;
  final int? alturaCm;
  final String? compleicao;
  final String? tatuagensMarcas;
  final String? veiculosAssociados;
  final String? modusOperandi;
  final String nivelPericulosidade;
  final String? orientacoesAbordagem;
  final String? boRaiNumero;
  final String fundamentacao;
  final DateTime? archivedAt;

  MapSuspectProfile({
    required this.pointId,
    this.apelido,
    this.caracteristicasFisicas,
    this.alturaCm,
    this.compleicao,
    this.tatuagensMarcas,
    this.veiculosAssociados,
    this.modusOperandi,
    required this.nivelPericulosidade,
    this.orientacoesAbordagem,
    this.boRaiNumero,
    required this.fundamentacao,
    this.archivedAt,
  });

  factory MapSuspectProfile.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return MapSuspectProfile(
      pointId: parseInt(json['point_id']) ?? 0,
      apelido: json['apelido'] as String?,
      caracteristicasFisicas: json['caracteristicas_fisicas'] as String?,
      alturaCm: parseInt(json['altura_cm']),
      compleicao: json['compleicao'] as String?,
      tatuagensMarcas: json['tatuagens_marcas'] as String?,
      veiculosAssociados: json['veiculos_associados'] as String?,
      modusOperandi: json['modus_operandi'] as String?,
      nivelPericulosidade: json['nivel_periculosidade'] as String? ?? 'BAIXO',
      orientacoesAbordagem: json['orientacoes_abordagem'] as String?,
      boRaiNumero: json['bo_rai_numero'] as String?,
      fundamentacao: json['fundamentacao'] as String? ?? '',
      archivedAt: json['archived_at'] != null
          ? DateTime.tryParse(json['archived_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'apelido': apelido,
        'caracteristicas_fisicas': caracteristicasFisicas,
        'altura_cm': alturaCm,
        'compleicao': compleicao,
        'tatuagens_marcas': tatuagensMarcas,
        'veiculos_associados': veiculosAssociados,
        'modus_operandi': modusOperandi,
        'nivel_periculosidade': nivelPericulosidade,
        'orientacoes_abordagem': orientacoesAbordagem,
        'bo_rai_numero': boRaiNumero,
        'fundamentacao': fundamentacao,
      };

  bool get isHighRisk =>
      nivelPericulosidade == 'ALTO' || nivelPericulosidade == 'ARMADO';
}
