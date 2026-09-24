import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:permuta_policial/core/services/documento_auto_crop_stub.dart';
import 'package:permuta_policial/core/services/documento_orientation_detector_stub.dart';

img.Image _sample(int w, int h) {
  final image = img.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      image.setPixelRgba(x, y, x % 255, y % 255, 128, 255);
    }
  }
  return image;
}

void main() {
  group('modo degradado (stub sem JS interop)', () {
    test('DocumentoOrientationDetector retorna false sem rotacionar', () async {
      final image = _sample(200, 300);
      final needsFlip = await DocumentoOrientationDetector.detectFlip(image);
      expect(needsFlip, isFalse);
    });

    test('DocumentoAutoCrop devolve imagem original quando JS indisponível', () async {
      final image = _sample(400, 600);
      final result = await DocumentoAutoCrop.tryCropAndWarp(image);

      expect(result.wasCropped, isFalse);
      expect(result.image.width, image.width);
      expect(result.image.height, image.height);
    });
  });
}
