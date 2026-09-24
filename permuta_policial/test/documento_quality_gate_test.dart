import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:permuta_policial/core/services/documento_quality_gate.dart';

img.Image _solidGray(int width, int height, int value) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgba(x, y, value, value, value, 255);
    }
  }
  return image;
}

img.Image _checkerSharp(int width, int height) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final v = (x ~/ 4 + y ~/ 4) % 2 == 0 ? 20 : 230;
      image.setPixelRgba(x, y, v, v, v, 255);
    }
  }
  return image;
}

img.Image _blurred(int width, int height) {
  final sharp = _checkerSharp(width, height);
  return img.gaussianBlur(sharp, radius: 6);
}

void main() {
  group('DocumentoQualityGate', () {
    test('foto nítida e bem exposta é aceitável', () {
      final image = _checkerSharp(320, 240);
      final result = DocumentoQualityGate.check(image);

      expect(result.isBlurry, isFalse);
      expect(result.isTooDark, isFalse);
      expect(result.isTooBright, isFalse);
      expect(result.isAcceptable, isTrue);
    });

    test('foto borrada é reprovada', () {
      final image = _blurred(320, 240);
      final result = DocumentoQualityGate.check(image);

      expect(result.isBlurry, isTrue);
      expect(result.isAcceptable, isFalse);
    });

    test('foto escura é reprovada', () {
      final image = _solidGray(320, 240, 10);
      final result = DocumentoQualityGate.check(image);

      expect(result.isTooDark, isTrue);
      expect(result.isAcceptable, isFalse);
    });

    test('foto clara demais é reprovada', () {
      final image = _solidGray(320, 240, 245);
      final result = DocumentoQualityGate.check(image);

      expect(result.isTooBright, isTrue);
      expect(result.isAcceptable, isFalse);
    });
  });
}
