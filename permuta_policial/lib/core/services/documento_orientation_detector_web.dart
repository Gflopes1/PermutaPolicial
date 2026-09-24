import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Detecção best-effort de foto de cabeça para baixo via rosto (BlazeFace).
///
/// O rosto é mais estável que texto OCR para decidir flip 180°. Se o modelo JS
/// não carregar, não encontrar rosto ou estourar timeout, retorna `false` e o
/// fallback multi-orientação existente assume o controle.
class DocumentoOrientationDetector {
  DocumentoOrientationDetector._();

  static const Duration _timeout = Duration(milliseconds: 1500);

  static Future<bool> detectFlip(img.Image image) async {
    try {
      final jpeg = Uint8List.fromList(img.encodeJpg(image, quality: 90));
      final dataUrl =
          'data:image/jpeg;base64,${base64Encode(jpeg)}';

      final result = await _detectFlipJs(dataUrl.toJS)
          .toDart
          .timeout(_timeout, onTimeout: () => {'needsFlip': false}.jsify());

      if (result == null) return false;
      final map = (result as JSObject).dartify();
      if (map is! Map) return false;
      return map['needsFlip'] == true;
    } catch (_) {
      return false;
    }
  }
}

@JS('permutaDocOrientation.detectFlip')
external JSPromise _detectFlipJs(JSString dataUrl);
