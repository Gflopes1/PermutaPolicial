import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Garante que o SW do FCM (`/firebase-messaging-sw.js`) está registrado e ativo.
/// Necessário antes de `getToken` — conflito com o SW do Flutter causa
/// "Registration failed - push service error".
Future<void> ensureFcmServiceWorkerReady() async {
  final swContainer = web.window.navigator.serviceWorker;

  // Aguarda registro early do index.html, se ainda estiver em andamento.
  try {
    final early = web.window.getProperty('__permutaFcmSwReady'.toJS);
    if (early != null) {
      await (early as JSPromise).toDart;
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('ℹ️ FCM: early SW promise — $e');
    }
  }

  await swContainer
      .register('/firebase-messaging-sw.js'.toJS)
      .toDart;

  await swContainer.ready.toDart;

  if (kDebugMode) {
    debugPrint('✅ FCM: firebase-messaging-sw.js registrado e pronto');
  }
}
