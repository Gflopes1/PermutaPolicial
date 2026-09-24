import 'package:image/image.dart' as img;

/// Stub fora da web — sem detecção de rosto; fallback multi-orientação cobre.
class DocumentoOrientationDetector {
  DocumentoOrientationDetector._();

  static Future<bool> detectFlip(img.Image image) async => false;
}
