import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Pré-processamento de imagem antes do OCR: orientação EXIF, escala padronizada,
/// contraste adaptativo por tile, nitidez e upscale para fotos pequenas.
class DocumentoImagePreprocess {
  DocumentoImagePreprocess._();

  static const int minWidthForOcr = 1200;

  /// Largura alvo após crop — padroniza escala enviada ao Vision.
  static const int standardWidth = 1600;

  static const int claheTileSize = 64;
  static const List<int> orientacoesGraus = [0, 90, 180, 270];

  static img.Image prepare(img.Image source) {
    var image = img.bakeOrientation(source);

    if (image.width > standardWidth) {
      image = img.copyResize(
        image,
        width: standardWidth,
        interpolation: img.Interpolation.cubic,
      );
    }

    if (image.width < minWidthForOcr) {
      image = img.copyResize(
        image,
        width: minWidthForOcr,
        interpolation: img.Interpolation.linear,
      );
    }

    image = img.grayscale(image);
    image = _enhanceContrastAdaptive(image);
    image = _sharpen(image);

    return image;
  }

  /// Gera variantes pré-processadas em 0°, 90°, 180° e 270° (sentido horário).
  static List<({int angle, img.Image image})> prepareOrientations(img.Image source) {
    final base = prepare(source);
    return [
      for (final angle in orientacoesGraus)
        (
          angle: angle,
          image: angle == 0 ? base : img.copyRotate(base, angle: angle.toDouble()),
        ),
    ];
  }

  /// CLAHE simplificado: interpola curvas min/max entre tiles vizinhos no mesmo pixel.
  static img.Image _enhanceContrastAdaptive(img.Image image) {
    if (image.width < claheTileSize || image.height < claheTileSize) {
      return _enhanceContrastGlobal(image);
    }

    try {
      final w = image.width;
      final h = image.height;
      final tile = claheTileSize;
      final cols = (w + tile - 1) ~/ tile;
      final rows = (h + tile - 1) ~/ tile;

      final tileMin = List<int>.filled(rows * cols, 255);
      final tileMax = List<int>.filled(rows * cols, 0);

      const minRange = 25;

      for (var row = 0; row < rows; row++) {
        for (var col = 0; col < cols; col++) {
          final x0 = col * tile;
          final y0 = row * tile;
          final x1 = (x0 + tile > w) ? w : x0 + tile;
          final y1 = (y0 + tile > h) ? h : y0 + tile;

          var minVal = 255;
          var maxVal = 0;
          for (var y = y0; y < y1; y++) {
            for (var x = x0; x < x1; x++) {
              final v = image.getPixel(x, y).r.toInt();
              if (v < minVal) minVal = v;
              if (v > maxVal) maxVal = v;
            }
          }
          if (maxVal - minVal < minRange) {
            minVal = 0;
            maxVal = 255;
          }
          tileMin[row * cols + col] = minVal;
          tileMax[row * cols + col] = maxVal;
        }
      }

      double mapValue(int original, int idx) {
        final minVal = tileMin[idx];
        final maxVal = tileMax[idx];
        if (maxVal <= minVal) return original.toDouble();
        final v = (original - minVal) * 255.0 / (maxVal - minVal);
        return v.clamp(0, 255);
      }

      final out = img.Image(width: w, height: h, numChannels: image.numChannels);

      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final original = image.getPixel(x, y).r.toInt();

          final tx = x / tile - 0.5;
          final ty = y / tile - 0.5;

          final col0 = tx.floor().clamp(0, cols - 1);
          final row0 = ty.floor().clamp(0, rows - 1);
          final col1 = (col0 + 1).clamp(0, cols - 1);
          final row1 = (row0 + 1).clamp(0, rows - 1);

          final fx = (tx - tx.floor()).clamp(0.0, 1.0);
          final fy = (ty - ty.floor()).clamp(0.0, 1.0);

          final v00 = mapValue(original, row0 * cols + col0);
          final v10 = mapValue(original, row0 * cols + col1);
          final v01 = mapValue(original, row1 * cols + col0);
          final v11 = mapValue(original, row1 * cols + col1);

          final top = v00 * (1 - fx) + v10 * fx;
          final bottom = v01 * (1 - fx) + v11 * fx;
          final value = (top * (1 - fy) + bottom * fy).round().clamp(0, 255);

          out.setPixelRgba(x, y, value, value, value, 255);
        }
      }

      return out;
    } catch (_) {
      return _enhanceContrastGlobal(image);
    }
  }

  static img.Image _enhanceContrastGlobal(img.Image image) {
    var enhanced = img.normalize(image, min: 15, max: 240);
    enhanced = img.adjustColor(
      enhanced,
      contrast: 1.55,
      brightness: 1.06,
      gamma: 0.88,
    );
    return enhanced;
  }

  static img.Image _sharpen(img.Image image) {
    return img.convolution(
      image,
      filter: [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0,
      ],
    );
  }

  static Uint8List encodeJpeg(img.Image image, {int quality = 92}) {
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }

  /// Rotação 180° determinística (correção de flip detectado por rosto).
  static img.Image rotate180(img.Image source) {
    return img.copyRotate(source, angle: 180);
  }
}
