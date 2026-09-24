import 'documento_quality_gate.dart';

/// Imagem reprovada no gate de qualidade — pedir nova foto ao usuário.
class DocumentoQualityException implements Exception {
  final QualityCheckResult quality;

  const DocumentoQualityException(this.quality);

  @override
  String toString() => quality.userMessage;
}
