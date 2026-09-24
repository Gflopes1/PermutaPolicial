import 'web_firebase_config_models.dart';
import 'web_firebase_config_stub.dart'
    if (dart.library.js_interop) 'web_firebase_config_web.dart' as impl;

export 'web_firebase_config_models.dart' show WebFirebaseRuntimeConfig;

Future<WebFirebaseRuntimeConfig?> loadWebFirebaseRuntimeConfig() =>
    impl.loadWebFirebaseRuntimeConfig();
