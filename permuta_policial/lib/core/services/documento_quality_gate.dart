import 'package:image/image.dart' as img;

/// Gate de qualidade antes do OCR: nitidez e exposição.
///
/// Calibrado empiricamente em fotos de crachá (webcam/celular). Ajuste os
/// thresholds se o fluxo reprovar demais ou aceitar fotos ilegíveis.
class DocumentoQualityGate {
  DocumentoQualityGate._();

  /// Variância do Laplaciano abaixo disso indica foto borrada.
  /// Referência típica: foto nítida de documento > 120; borrada < 40.
  static const double laplacianVarianceMin = 45.0;

  /// Média de luminância (0–255) — abaixo = escuro demais.
  static const double meanLuminanceMin = 35.0;

  /// Média de luminância — acima = estourada/clara demais.
  static const double meanLuminanceMax = 230.0;

  static QualityCheckResult check(img.Image source) {
    final gray = source.numChannels == 1 ? source : img.grayscale(source);
    final lapVar = _laplacianVariance(gray);
    final mean = _meanLuminance(gray);

    return QualityCheckResult(
      laplacianVariance: lapVar,
      meanLuminance: mean,
      isBlurry: lapVar < laplacianVarianceMin,
      isTooDark: mean < meanLuminanceMin,
      isTooBright: mean > meanLuminanceMax,
    );
  }

  static double _meanLuminance(img.Image gray) {
    if (gray.width == 0 || gray.height == 0) return 0;
    var sum = 0.0;
    final pixels = gray.width * gray.height;
    for (var y = 0; y < gray.height; y++) {
      for (var x = 0; x < gray.width; x++) {
        sum += gray.getPixel(x, y).r;
      }
    }
    return sum / pixels;
  }

  /// Kernel Laplaciano [0,1,0 / 1,-4,1 / 0,1,0] — variância mede nitidez.
  static double _laplacianVariance(img.Image gray) {
    final w = gray.width;
    final h = gray.height;
    if (w < 3 || h < 3) return 0;

    final responses = <double>[];
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        final c = gray.getPixel(x, y).r.toDouble();
        final n = gray.getPixel(x, y - 1).r.toDouble();
        final s = gray.getPixel(x, y + 1).r.toDouble();
        final e = gray.getPixel(x + 1, y).r.toDouble();
        final wP = gray.getPixel(x - 1, y).r.toDouble();
        final lap = (n + s + e + wP - 4 * c).abs();
        responses.add(lap);
      }
    }

    if (responses.isEmpty) return 0;
    final mean = responses.reduce((a, b) => a + b) / responses.length;
    var variance = 0.0;
    for (final v in responses) {
      final d = v - mean;
      variance += d * d;
    }
    return variance / responses.length;
  }
}

class QualityCheckResult {
  final double laplacianVariance;
  final double meanLuminance;
  final bool isBlurry;
  final bool isTooDark;
  final bool isTooBright;

  const QualityCheckResult({
    required this.laplacianVariance,
    required this.meanLuminance,
    required this.isBlurry,
    required this.isTooDark,
    required this.isTooBright,
  });

  bool get isAcceptable => !isBlurry && !isTooDark && !isTooBright;

  String get userMessage {
    if (isBlurry) {
      return 'A foto está borrada. Segure o aparelho firme e tente novamente.';
    }
    if (isTooDark) {
      return 'A foto está escura demais. Melhore a iluminação e tente novamente.';
    }
    if (isTooBright) {
      return 'A foto está clara demais (estourada). Evite reflexo direto e tente novamente.';
    }
    return 'Qualidade da imagem aceitável.';
  }
}
