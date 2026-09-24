// /lib/core/models/forca_policial.dart

class ForcaPolicial {
  final int id;
  final String nome;
  final String sigla;
  final String tipo;
  final String tipoPermuta;

  ForcaPolicial({
    required this.id, 
    required this.nome, 
    required this.sigla,
    required this.tipo,
    required this.tipoPermuta,
  });

  factory ForcaPolicial.fromJson(Map<String, dynamic> json) {
    return ForcaPolicial(
      id: json['id'],
      nome: json['nome'] ?? 'Nome não informado',
      sigla: json['sigla'] ?? 'N/A',
      tipo: json['tipo'] ?? '',
      tipoPermuta: json['tipo_permuta'] ?? '',
    );
  }
}