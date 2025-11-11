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
  final int como1Opcao;
  final int como2Opcao;
  final int como3Opcao;

  Competicao({
    required this.como1Opcao,
    required this.como2Opcao,
    required this.como3Opcao,
  });

  factory Competicao.fromJson(Map<String, dynamic> json) {
    return Competicao(
      como1Opcao: json['como_1_opcao'] as int,
      como2Opcao: json['como_2_opcao'] as int,
      como3Opcao: json['como_3_opcao'] as int,
    );
  }
}