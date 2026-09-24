// Configuração Firebase — preencha via `flutterfire configure` ou --dart-define no build.
// Web push: veja WEB_PUSH_SETUP.md

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const String _apiKey =
      String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
  static const String _appId =
      String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');
  static const String _webAppId =
      String.fromEnvironment('FIREBASE_WEB_APP_ID', defaultValue: '');
  static const String _messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');
  static const String _projectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static const String _authDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: '');
  static const String _storageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '');
  static const String _vapidKey =
      String.fromEnvironment('FIREBASE_VAPID_KEY', defaultValue: '');

  /// Chave VAPID (Web Push) — Firebase Console → Cloud Messaging → Web Push certificates.
  static String get vapidKey => _vapidKey;

  static bool get isConfigured {
    if (kIsWeb) {
      return _projectId.isNotEmpty &&
          _apiKey.isNotEmpty &&
          _messagingSenderId.isNotEmpty &&
          (_webAppId.isNotEmpty || _appId.isNotEmpty) &&
          _vapidKey.isNotEmpty;
    }
    return _projectId.isNotEmpty && _appId.isNotEmpty && _apiKey.isNotEmpty;
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Plataforma não suportada para Firebase.');
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _apiKey,
        appId: _webAppId.isNotEmpty ? _webAppId : _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _authDomain.isNotEmpty
            ? _authDomain
            : '$_projectId.firebaseapp.com',
        storageBucket: _storageBucket.isNotEmpty
            ? _storageBucket
            : '$_projectId.appspot.com',
      );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    iosBundleId: 'br.com.permutapolicial.app',
  );
}
