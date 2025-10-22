// /lib/core/models/ponto_mapa.dart

class PontoMapa {
  final int municipioId;
  final String nome;
  final double latitude;
  final double longitude;
  final int contagem;
  final int? balanco;
  final int? volume;

  PontoMapa({
    required this.municipioId,
    required this.nome,
    required this.latitude,
    required this.longitude,
    required this.contagem,
    this.balanco,
    this.volume,
  });

  factory PontoMapa.fromJson(Map<String, dynamic> json) {
    // A latitude e a longitude podem vir como String ou double da API.
    // Garantimos a conversão segura para double.
    final lat = double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0;
    final lon = double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0;

    return PontoMapa(
      municipioId: json['id'],
      nome: json['nome'] ?? 'N/A',
      latitude: lat,
      longitude: lon,
      contagem: json['contagem'] ?? 0,
      balanco: json['balanco'],
      volume: json['volume'],
    );
  }
}