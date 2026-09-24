class IntencoesSoldado {
  final int? escolha1OpmId;
  final int? escolha2OpmId;
  final int? escolha3OpmId;

  IntencoesSoldado({
    this.escolha1OpmId,
    this.escolha2OpmId,
    this.escolha3OpmId,
  });

  factory IntencoesSoldado.fromJson(Map<String, dynamic> json) {
    return IntencoesSoldado(
      escolha1OpmId: (json['escolha_1_vaga_id'] ?? json['escolha_1_opm_id']) as int?,
      escolha2OpmId: (json['escolha_2_vaga_id'] ?? json['escolha_2_opm_id']) as int?,
      escolha3OpmId: (json['escolha_3_vaga_id'] ?? json['escolha_3_opm_id']) as int?,
    );
  }
}