import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'web_firebase_config_models.dart';

/// Sempre na raiz do site — `Uri.base.resolve('...')` quebra em `/auth/callback` etc.
Uri webFirebasePushConfigUri() =>
    Uri.parse('${Uri.base.origin}/firebase-push-config.json');

Future<WebFirebaseRuntimeConfig?> loadWebFirebaseRuntimeConfig() async {
  final uri = webFirebasePushConfigUri();
  try {
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      debugPrint(
        '⚠️ firebase-push-config.json: HTTP ${response.statusCode} em $uri',
      );
      return null;
    }

    final map = jsonDecode(response.body);
    if (map is! Map) return null;

    String s(String key) => map[key]?.toString().trim() ?? '';

    final config = WebFirebaseRuntimeConfig(
      apiKey: s('apiKey'),
      appId: s('appId'),
      projectId: s('projectId'),
      messagingSenderId: s('messagingSenderId'),
      authDomain: s('authDomain'),
      storageBucket: s('storageBucket'),
      vapidKey: s('vapidKey'),
    );

    // Retorna mesmo inválido para o banner exibir qual campo falta (ex.: vapidKey).
    return config.apiKey.isNotEmpty && config.projectId.isNotEmpty ? config : null;
  } catch (e) {
    debugPrint('⚠️ firebase-push-config.json: falha ao carregar $uri — $e');
    return null;
  }
}
