import 'web_resume_bridge_stub.dart'
    if (dart.library.js_interop) 'web_resume_bridge_web.dart' as impl;

typedef WebResumeCallback = void Function();

void registerWebResumeListener(WebResumeCallback callback) =>
    impl.registerWebResumeListener(callback);

void markFlutterAppReady() => impl.markFlutterAppReady();

/// Evita reload da página ao voltar da aba durante file picker, câmera ou OCR.
void suppressWebResumeReload({Duration duration = const Duration(seconds: 20)}) =>
    impl.suppressWebResumeReload(duration: duration);

void setWebOcrInProgress(bool inProgress) => impl.setWebOcrInProgress(inProgress);
