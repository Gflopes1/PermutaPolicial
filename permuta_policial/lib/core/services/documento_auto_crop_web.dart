import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'documento_auto_crop_stub.dart' show AutoCropResult;

/// Auto-crop + correção de perspectiva via opencv.js (document scanner).
///
/// Deskew fino sem crop confiável não é aplicado — rotacionar sem contorno
/// claro arriscaria piorar a imagem; o fallback multi-orientação cobre esse caso.
class DocumentoAutoCrop {
  DocumentoAutoCrop._();

  static Future<AutoCropResult> tryCropAndWarp(img.Image source) async {
    try {
      final jpeg = Uint8List.fromList(img.encodeJpg(source, quality: 92));
      final dataUrl =
          'data:image/jpeg;base64,${base64Encode(jpeg)}';

      final result = await _tryCropAndWarpJs(dataUrl.toJS).toDart;
      if (result == null) {
        return AutoCropResult(image: source, wasCropped: false);
      }

      final map = (result as JSObject).dartify();
      if (map is! Map) {
        return AutoCropResult(image: source, wasCropped: false);
      }

      final wasCropped = map['wasCropped'] == true;
      final outUrl = map['dataUrl']?.toString();
      if (!wasCropped || outUrl == null || outUrl.isEmpty) {
        return AutoCropResult(image: source, wasCropped: false);
      }

      final decoded = _decodeDataUrl(outUrl);
      if (decoded == null) {
        return AutoCropResult(image: source, wasCropped: false);
      }

      return AutoCropResult(image: decoded, wasCropped: true);
    } catch (_) {
      return AutoCropResult(image: source, wasCropped: false);
    }
  }

  static img.Image? _decodeDataUrl(String dataUrl) {
    try {
      final comma = dataUrl.indexOf(',');
      if (comma < 0) return null;
      final bytes = base64Decode(dataUrl.substring(comma + 1));
      return img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
  }
}

@JS('permutaDocAutoCrop.tryCropAndWarp')
external JSPromise _tryCropAndWarpJs(JSString dataUrl);
