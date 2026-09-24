import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Junta as faces já redigidas num único JPEG para o envio/revisão, mantendo o
/// contrato de upload de uma imagem só.
class DocumentoFacesImage {
  DocumentoFacesImage._();

  static const int _maxWidth = 1600;
  static const int _separatorHeight = 8;

  static Uint8List stackVertically(List<Uint8List> faces) {
    if (faces.length == 1) return faces.first;

    final decoded = faces
        .map(img.decodeImage)
        .whereType<img.Image>()
        .toList(growable: false);

    if (decoded.isEmpty) return faces.first;
    if (decoded.length == 1) {
      return Uint8List.fromList(img.encodeJpg(decoded.first, quality: 88));
    }

    final targetWidth = decoded
        .map((image) => image.width)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, _maxWidth);

    final normalized = decoded
        .map(
          (image) => image.width == targetWidth
              ? image
              : img.copyResize(
                  image,
                  width: targetWidth,
                  interpolation: img.Interpolation.linear,
                ),
        )
        .toList(growable: false);

    final totalHeight = normalized.fold<int>(0, (sum, image) => sum + image.height) +
        _separatorHeight * (normalized.length - 1);

    final canvas = img.Image(width: targetWidth, height: totalHeight);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

    var offsetY = 0;
    for (final face in normalized) {
      img.compositeImage(canvas, face, dstX: 0, dstY: offsetY);
      offsetY += face.height + _separatorHeight;
    }

    return Uint8List.fromList(img.encodeJpg(canvas, quality: 86));
  }
}
