// Bridge vazio para plataformas nativas (Android/iOS).

typedef WebResumeCallback = void Function();

void registerWebResumeListener(WebResumeCallback callback) {}

void markFlutterAppReady() {}

void suppressWebResumeReload({Duration duration = const Duration(seconds: 20)}) {}

void setWebOcrInProgress(bool inProgress) {}
