import 'dart:typed_data';

import 'documento_preprocess_debug.dart';
import 'verificacao_ocr_redaction.dart';

typedef DocumentoOcrProgressCallback = void Function(String status, double progress);

class DocumentoOcrResult {
  /// Foto original enviada para auditoria (sem censura).
  final Uint8List auditBytes;
  final ExtractedVerificationFields fields;
  final List<OcrTextBlock> blocks;
  final String? visionRawText;
  final bool imageWasCompressed;
  final String? originalImageSizeLabel;

  /// Etapas do pré-processamento (web) — visível só no painel admin.
  final List<DocumentoPreprocessStep> preprocessSteps;

  const DocumentoOcrResult({
    required this.auditBytes,
    required this.fields,
    required this.blocks,
    this.visionRawText,
    this.imageWasCompressed = false,
    this.originalImageSizeLabel,
    this.preprocessSteps = const [],
  });

  @Deprecated('Use auditBytes')
  Uint8List get redactedBytes => auditBytes;
}
