import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'documento_image_preprocess.dart';

/// Normaliza fotos pesadas (3 MB+, alta resolução) antes do OCR e da redação.
class DocumentoImageLoader {
  DocumentoImageLoader._();

  static const int maxBytesBeforeReencode = 3 * 1024 * 1024;
  static const int maxDimensionPx = 3200;
  static const int jpegQualityHeavy = 88;

  static LoadedDocumentImage load(Uint8List rawBytes) {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      throw FormatException('Não foi possível ler a imagem selecionada.');
    }

    var image = img.bakeOrientation(decoded);
    image = _limitDimensions(image);

    final needsReencode =
        rawBytes.length > maxBytesBeforeReencode ||
        image.width != decoded.width ||
        image.height != decoded.height;

    final normalizedBytes = needsReencode
        ? DocumentoImagePreprocess.encodeJpeg(image, quality: jpegQualityHeavy)
        : rawBytes;

    return LoadedDocumentImage(
      originalBytes: normalizedBytes,
      decoded: image,
      wasCompressed: needsReencode,
      originalSizeBytes: rawBytes.length,
    );
  }

  static img.Image _limitDimensions(img.Image image) {
    final longest = image.width > image.height ? image.width : image.height;
    if (longest <= maxDimensionPx) return image;

    if (image.width >= image.height) {
      return img.copyResize(
        image,
        width: maxDimensionPx,
        interpolation: img.Interpolation.linear,
      );
    }

    return img.copyResize(
      image,
      height: maxDimensionPx,
      interpolation: img.Interpolation.linear,
    );
  }
}

class LoadedDocumentImage {
  final Uint8List originalBytes;
  final img.Image decoded;
  final bool wasCompressed;
  final int originalSizeBytes;

  const LoadedDocumentImage({
    required this.originalBytes,
    required this.decoded,
    required this.wasCompressed,
    required this.originalSizeBytes,
  });

  String get sizeLabel {
    final mb = originalSizeBytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    return '${(originalSizeBytes / 1024).round()} KB';
  }
}
