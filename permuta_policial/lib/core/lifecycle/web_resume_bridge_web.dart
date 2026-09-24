// Bridge web: escuta retorno de visibilidade e eventos de recuperação do index.html.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

typedef WebResumeCallback = void Function();

void registerWebResumeListener(WebResumeCallback callback) {
  void onVisible() {
    if (web.document.visibilityState == 'visible') {
      callback();
    }
  }

  web.document.addEventListener(
    'visibilitychange',
    ((web.Event _) => onVisible()).toJS,
  );

  web.window.addEventListener(
    'pageshow',
    ((web.Event event) {
      final pageEvent = event as web.PageTransitionEvent;
      if (pageEvent.persisted) {
        callback();
      }
    }).toJS,
  );

  web.window.addEventListener(
    'permuta-app-resume',
    ((web.Event _) => callback()).toJS,
  );
}

void markFlutterAppReady() {
  try {
    web.window.setProperty('__permutaFlutterReady'.toJS, true.toJS);
  } catch (_) {}
}

void suppressWebResumeReload({Duration duration = const Duration(seconds: 20)}) {
  try {
    final until = DateTime.now().add(duration).millisecondsSinceEpoch;
    web.window.setProperty('__permutaSuppressResumeUntil'.toJS, until.toJS);
  } catch (_) {}
}

void setWebOcrInProgress(bool inProgress) {
  try {
    web.window.setProperty('__permutaOcrInProgress'.toJS, inProgress.toJS);
  } catch (_) {}
}
