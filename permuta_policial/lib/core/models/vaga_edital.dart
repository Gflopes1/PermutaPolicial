class VagaEdital {
  final int id;
  final String crpm;
  final String opm;
  final int vagasDisponiveis;

  VagaEdital({
    required this.id,
    required this.crpm,
    required this.opm,
    required this.vagasDisponiveis,
  });

  factory VagaEdital.fromJson(Map<String, dynamic> json) {
    return VagaEdital(
      id: json['id'] as int,
      crpm: json['crpm'] as String,
      opm: json['opm'] as String,
      vagasDisponiveis: json['vagas_disponiveis'] as int,
    );
  }

  // Isto é útil para o teu CustomDropdownSearch
  @override
  String toString() {
    return '$opm ($crpm)';
  }
}