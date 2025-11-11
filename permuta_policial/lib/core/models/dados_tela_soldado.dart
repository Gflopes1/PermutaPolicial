import 'package:permuta_policial/core/models/intencoes_soldado.dart';
import 'package:permuta_policial/core/models/vaga_edital.dart';

class DadosTelaSoldado {
  final List<VagaEdital> vagasDisponiveis;
  final IntencoesSoldado? minhasIntencoes; // Pode ser nulo se for a primeira vez
  final int minhaPosicao;

  DadosTelaSoldado({
    required this.vagasDisponiveis,
    this.minhasIntencoes,
    required this.minhaPosicao,
  });

  factory DadosTelaSoldado.fromJson(Map<String, dynamic> json) {
    // 1. Processa a lista de vagas
    final List<VagaEdital> vagas = (json['vagasDisponiveis'] as List)
        .map((vagaJson) => VagaEdital.fromJson(vagaJson))
        .toList();

    // 2. Processa as intenções (se existirem)
    final IntencoesSoldado? intencoes = json['minhasIntencoes'] != null
        ? IntencoesSoldado.fromJson(json['minhasIntencoes'])
        : null;

    return DadosTelaSoldado(
      vagasDisponiveis: vagas,
      minhasIntencoes: intencoes,
      minhaPosicao: json['minhaPosicao'] as int,
    );
  }
}