class AnaliseVaga {
  final VagaInfo vagaInfo;
  final int minhaPosicao;
  final Competicao competicao;

  AnaliseVaga({
    required this.vagaInfo,
    required this.minhaPosicao,
    required this.competicao,
  });

  factory AnaliseVaga.fromJson(Map<String, dynamic> json) {
    return AnaliseVaga(
      vagaInfo: VagaInfo.fromJson(json['vagaInfo']),
      minhaPosicao: json['minhaPosicao'] as int,
      competicao: Competicao.fromJson(json['competicao']),
    );
  }
}

// Sub-model (aninhado)
class VagaInfo {
  final String opm;
  final int vagasDisponiveis;

  VagaInfo({required this.opm, required this.vagasDisponiveis});

  factory VagaInfo.fromJson(Map<String, dynamic> json) {
    return VagaInfo(
      opm: json['opm'] as String,
      vagasDisponiveis: json['vagas_disponiveis'] as int,
    );
  }
}

// Sub-model (aninhado)
class Competicao {
  final int totalInteressados;
  final int maisAntigos;
  final int maisModernos;
  final int como1Opcao;
  final int como2Opcao;
  final int como3Opcao;

  Competicao({
    required this.totalInteressados,
    required this.maisAntigos,
    required this.maisModernos,
    required this.como1Opcao,
    required this.como2Opcao,
    required this.como3Opcao,
  });

  factory Competicao.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => (v as num?)?.toInt() ?? 0;
    return Competicao(
      totalInteressados: asInt(json['total_interessados']),
      maisAntigos: asInt(json['mais_antigos']),
      maisModernos: asInt(json['mais_modernos']),
      como1Opcao: asInt(json['como_1_opcao']),
      como2Opcao: asInt(json['como_2_opcao']),
      como3Opcao: asInt(json['como_3_opcao']),
    );
  }
}
