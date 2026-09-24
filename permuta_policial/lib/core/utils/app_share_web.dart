import 'dart:js_interop';

import 'package:flutter/services.dart';import 'package:web/web.dart' as web;

/// Compartilha [text] via Web Share API ou copia para a área de transferência.
/// Retorna `true` se o sheet nativo foi usado; `false` se caiu no fallback (clipboard).
Future<bool> shareText(String text, {String? subject}) async {
  final data = web.ShareData(text: text);
  if (subject != null && subject.isNotEmpty) {
    data.title = subject;
  }

  try {
    if (web.window.navigator.canShare(data)) {
      await web.window.navigator.share(data).toDart;
      return true;
    }
  } catch (e) {
    final message = e.toString();
    if (message.contains('AbortError') || message.contains('NotAllowedError')) {
      return false;
    }
  }

  await Clipboard.setData(ClipboardData(text: text));
  return false;
}
