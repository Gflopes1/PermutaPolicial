import 'web_update_checker_stub.dart'
    if (dart.library.js_interop) 'web_update_checker_web.dart' as impl;

typedef WebUpdateAvailableCallback = void Function(String buildId);
typedef WebUpdateClearedCallback = void Function();

void registerWebUpdateListener(WebUpdateAvailableCallback callback) =>
    impl.registerWebUpdateListener(callback);

void registerWebUpdateClearedListener(WebUpdateClearedCallback callback) =>
    impl.registerWebUpdateClearedListener(callback);

void triggerWebUpdateCheck() => impl.triggerWebUpdateCheck();

Future<void> applyWebUpdate() => impl.applyWebUpdate();
