import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'documento_image_preprocess.dart';

/// Uma etapa do pipeline de pré-processamento — só preenchido na web (admin debug).
class DocumentoPreprocessStep {
  final String id;
  final String label;
  final Uint8List jpegBytes;
  final String? detail;

  const DocumentoPreprocessStep({
    required this.id,
    required this.label,
    required this.jpegBytes,
    this.detail,
  });
}

class DocumentoPreprocessDebug {
  DocumentoPreprocessDebug._();

  static DocumentoPreprocessStep fromImage(
    String id,
    String label,
    img.Image image, {
    String? detail,
    int jpegQuality = 85,
  }) {
    return DocumentoPreprocessStep(
      id: id,
      label: label,
      jpegBytes: DocumentoImagePreprocess.encodeJpeg(image, quality: jpegQuality),
      detail: detail,
    );
  }
}
