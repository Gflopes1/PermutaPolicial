import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui';

import 'documento_ocr_types.dart';

@JS('permutaOcrBridge.recognizeImage')
external JSPromise _recognizeImage(
  JSString dataUrl,
  JSString lang,
  JSFunction? onProgress,
);

@JS('permutaOcrBridge.redactImage')
external JSPromise _redactImage(
  JSString dataUrl,
  JSAny boxes,
);

@JS('permutaOcrBridge.bytesToDataUrl')
external JSString _bytesToDataUrl(
  JSUint8Array bytes,
  JSString mime,
);

@JS('permutaOcrBridge.dataUrlToBytes')
external JSUint8Array _dataUrlToBytes(JSString dataUrl);

class TesseractOcrBridgeWeb {
  static Future<({List<({String text, Rect rect})> lines, List<({String text, Rect rect})> words})>
      recognizeImage(
    Uint8List imageBytes, {
    DocumentoOcrProgressCallback? onProgress,
  }) async {
    final dataUrl = _bytesToDataUrl(imageBytes.toJS, 'image/jpeg'.toJS).toDart;

    JSFunction? progressFn;
    if (onProgress != null) {
      progressFn = ((JSString status, JSNumber progress) {
        onProgress(status.toDart, progress.toDartDouble);
      }).toJS;
    }

    final rawResult = await _recognizeImage(dataUrl.toJS, 'por'.toJS, progressFn).toDart;
    final jsonStr = (rawResult as JSString).toDart;

    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final lines = _parseItems(map['lines']);
    final words = _parseItems(map['words']);
    return (lines: lines, words: words);
  }

  static Future<Uint8List> redactImage(
    Uint8List imageBytes,
    List<Rect> rects,
  ) async {
    final dataUrl = _bytesToDataUrl(imageBytes.toJS, 'image/jpeg'.toJS).toDart;

    final boxes = rects
        .map(
          (r) => {
            'x0': r.left,
            'y0': r.top,
            'x1': r.right,
            'y1': r.bottom,
          }.jsify(),
        )
        .toList()
        .jsify();

    final rawRedacted = await _redactImage(dataUrl.toJS, boxes!).toDart;
    final redactedUrl = (rawRedacted as JSString).toDart;

    return _dataUrlToBytes(redactedUrl.toJS).toDart;
  }

  static List<({String text, Rect rect})> _parseItems(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((item) {
      final map = item as Map<String, dynamic>;
      return (
        text: map['text']?.toString() ?? '',
        rect: Rect.fromLTRB(
          (map['x0'] as num?)?.toDouble() ?? 0,
          (map['y0'] as num?)?.toDouble() ?? 0,
          (map['x1'] as num?)?.toDouble() ?? 0,
          (map['y1'] as num?)?.toDouble() ?? 0,
        ),
      );
    }).toList();
  }
}
