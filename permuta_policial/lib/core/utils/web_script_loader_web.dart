import 'dart:async';

import 'package:web/web.dart' as web;

/// Carrega scripts web sob demanda (OCR) — evita competir com o boot do Flutter.
class WebScriptLoader {
  WebScriptLoader._();

  static final _loaded = <String>{};
  static final _inFlight = <String, Future<void>>{};

  static Future<void> ensureOcrScriptsLoaded() {
    return Future.wait([
      _loadOnce('orientation_detector.js'),
      _loadOnce('documento_auto_crop.js'),
    ]);
  }

  static Future<void> _loadOnce(String src) {
    return _inFlight.putIfAbsent(src, () async {
      if (_loaded.contains(src)) return;

      final existing = web.document.querySelector('script[src="$src"]');
      if (existing != null) {
        _loaded.add(src);
        return;
      }

      final completer = Completer<void>();
      final script = web.HTMLScriptElement()
        ..src = src
        ..defer = true;

      script.onLoad.listen((_) {
        _loaded.add(src);
        if (!completer.isCompleted) completer.complete();
      });
      script.onError.listen((_) {
        if (!completer.isCompleted) completer.complete();
      });

      web.document.head!.appendChild(script);

      try {
        await completer.future.timeout(const Duration(seconds: 20));
      } on TimeoutException {
        // OCR segue com fallback multi-orientação se scripts não carregarem.
      } finally {
        _inFlight.remove(src);
      }
    });
  }
}
