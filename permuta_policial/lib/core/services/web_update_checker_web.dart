import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

typedef WebUpdateAvailableCallback = void Function(String buildId);

typedef WebUpdateClearedCallback = void Function();

void registerWebUpdateListener(WebUpdateAvailableCallback callback) {
  web.window.addEventListener(
    'permuta-update-available',
    ((web.Event _) {
      try {
        final buildId = _readPendingBuildId();
        if (buildId != null && buildId.isNotEmpty) {
          callback(buildId);
        }
      } catch (e, st) {
        debugPrint('⚠️ WebUpdateChecker listener: $e\n$st');
      }
    }).toJS,
  );
}

void registerWebUpdateClearedListener(WebUpdateClearedCallback callback) {
  web.window.addEventListener(
    'permuta-update-cleared',
    ((web.Event _) {
      try {
        callback();
      } catch (e, st) {
        debugPrint('⚠️ WebUpdateChecker cleared: $e\n$st');
      }
    }).toJS,
  );
}

String? _readPendingBuildId() {
  try {
    final value = web.window.getProperty('__permutaPendingBuildId'.toJS);
    if (value == null || value.isUndefinedOrNull) return null;
    return (value as JSString).toDart;
  } catch (_) {
    return null;
  }
}

void triggerWebUpdateCheck() {
  try {
    web.window.dispatchEvent(web.Event('permuta-force-update-check'));
  } catch (e) {
    debugPrint('⚠️ WebUpdateChecker check: $e');
  }
}

Future<void> applyWebUpdate() async {
  try {
    final applyFn = web.window.getProperty('__permutaApplyUpdate'.toJS);
    if (applyFn != null && !applyFn.isUndefinedOrNull) {
      (applyFn as JSFunction).callAsFunction();
      return;
    }
    web.window.dispatchEvent(web.Event('permuta-apply-update'));
  } catch (e) {
    debugPrint('⚠️ WebUpdateChecker apply: $e');
  }
}
