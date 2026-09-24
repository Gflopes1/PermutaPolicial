import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';

/// Google Sign-In nativo no APK (sem abrir navegador externo).
class GoogleSignInService {
  GoogleSignInService._();
  static final GoogleSignInService instance = GoogleSignInService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  bool get isAvailable =>
      !kIsWeb && (AppConfig.googleServerClientId?.isNotEmpty ?? false);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final serverClientId = AppConfig.googleServerClientId;
    if (serverClientId == null || serverClientId.isEmpty) {
      throw StateError(
        'GOOGLE_SERVER_CLIENT_ID não configurado no build do APK.',
      );
    }
    await _googleSignIn.initialize(serverClientId: serverClientId);
    _initialized = true;
  }

  Future<String?> signInAndGetIdToken() async {
    if (kIsWeb) return null;

    await _ensureInitialized();

    try {
      final account = await _googleSignIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    await _googleSignIn.signOut();
  }
}
