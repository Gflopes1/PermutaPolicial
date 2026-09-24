import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../api/api_client.dart';
import '../config/web_firebase_config.dart';
import '../utils/fcm_service_worker.dart';
import '../utils/notification_navigation.dart';
import '../utils/web_notification_utils.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Push notifications (FCM) — Android, iOS e Web/PWA.
class PushNotificationService {
  PushNotificationService(this._apiClient);

  static const _kWebFcmTokenKey = 'web_fcm_token';
  static const _kWebPushSetupCompleteKey = 'web_push_setup_complete';

  final ApiClient _apiClient;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _currentToken;
  WebFirebaseRuntimeConfig? _webRuntimeConfig;
  bool _webConfigLoadAttempted = false;

  Future<void> _ensureWebConfigLoaded() async {
    if (!kIsWeb || _webConfigLoadAttempted) return;
    _webConfigLoadAttempted = true;
    _webRuntimeConfig = await loadWebFirebaseRuntimeConfig();
  }

  /// Web: lê firebase-push-config.json. Mobile: --dart-define.
  bool get isConfigured {
    if (kIsWeb) {
      if (_webRuntimeConfig?.isValid == true) return true;
      return DefaultFirebaseOptions.isConfigured;
    }
    return DefaultFirebaseOptions.isConfigured;
  }

  String? get webConfigIssue {
    if (!kIsWeb) return null;
    if (_webRuntimeConfig?.isValid == true) return null;
    if (DefaultFirebaseOptions.isConfigured) return null;
    if (!_webConfigLoadAttempted) return null;
    if (_webRuntimeConfig == null) {
      return 'Arquivo firebase-push-config.json não encontrado em ${Uri.base.origin}/firebase-push-config.json (confira deploy).';
    }
    if (_webRuntimeConfig!.vapidKey.isEmpty) {
      return 'vapidKey vazia em firebase-push-config.json (Firebase → Cloud Messaging → Web Push).';
    }
    return 'Config Firebase Web incompleta em firebase-push-config.json.';
  }

  String get _webVapidKey {
    if (_webRuntimeConfig != null && _webRuntimeConfig!.vapidKey.isNotEmpty) {
      return _webRuntimeConfig!.vapidKey;
    }
    return DefaultFirebaseOptions.vapidKey;
  }

  FirebaseOptions get _firebaseOptions {
    if (kIsWeb) {
      final rt = _webRuntimeConfig;
      if (rt != null && rt.isValid) {
        return FirebaseOptions(
          apiKey: rt.apiKey,
          appId: rt.appId,
          messagingSenderId: rt.messagingSenderId,
          projectId: rt.projectId,
          authDomain: rt.authDomain.isNotEmpty
              ? rt.authDomain
              : '${rt.projectId}.firebaseapp.com',
          storageBucket: rt.storageBucket.isNotEmpty
              ? rt.storageBucket
              : '${rt.projectId}.appspot.com',
        );
      }
    }
    return DefaultFirebaseOptions.currentPlatform;
  }

  String? get currentToken => _currentToken;
  bool get isInitialized => _initialized;

  bool get shouldPromptWebPermission {
    if (!kIsWeb || !isConfigured) return false;
    return getWebNotificationPermission() == 'default';
  }

  /// Web: push já concluído (token salvo + permissão concedida).
  Future<bool> isWebPushSetupComplete() async {
    if (!kIsWeb) return false;
    if (getWebNotificationPermission() != 'granted') return false;
    if (_currentToken != null && _currentToken!.isNotEmpty) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kWebPushSetupCompleteKey) == true &&
        (prefs.getString(_kWebFcmTokenKey)?.isNotEmpty ?? false);
  }

  Future<void> _restoreWebTokenFromPrefs() async {
    if (!kIsWeb) return;
    if (getWebNotificationPermission() != 'granted') return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kWebFcmTokenKey);
    if (stored != null && stored.isNotEmpty) {
      _currentToken = stored;
    }
  }

  Future<void> _persistWebToken(String token) async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWebFcmTokenKey, token);
    await prefs.setBool(_kWebPushSetupCompleteKey, true);
  }

  Future<void> _clearWebTokenPrefs() async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kWebFcmTokenKey);
    await prefs.remove(_kWebPushSetupCompleteKey);
  }

  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      await _ensureWebConfigLoaded();
    }

    if (!isConfigured) {
      debugPrint(
        '⚠️ Push: Firebase não configurado — ${webConfigIssue ?? "veja WEB_PUSH_SETUP.md"}',
      );
      return;
    }

    await Firebase.initializeApp(options: _firebaseOptions);

    // SW FCM: index.html registra cedo; aqui só aguarda estar pronto (sem getToken).
    if (kIsWeb) {
      try {
        await ensureFcmServiceWorkerReady();
      } catch (e) {
        debugPrint('⚠️ Push web: SW FCM na inicialização — $e');
      }
    }

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _initLocalNotificationsMobile();
    }

    final messaging = FirebaseMessaging.instance;

    if (kIsWeb) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      await _restoreWebTokenFromPrefs();
      if (_currentToken != null) {
        await registerTokenWithBackend();
      }
    } else {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _handleRemoteMessage(initial);
    }

    messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      registerTokenWithBackend();
    });

    if (!kIsWeb) {
      _currentToken = await messaging.getToken();
      await registerTokenWithBackend();
    }

    _initialized = true;
  }

  Future<bool> requestWebPermissionAndRegister() async {
    if (!kIsWeb) return false;

    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) return false;

    final before = getWebNotificationPermission();
    debugPrint('📬 Push web: permissão do navegador antes do pedido: $before');

    if (before == 'denied') {
      debugPrint(
        '⚠️ Push web: permissão já bloqueada no navegador — libere em Configurações do site',
      );
      return false;
    }

    if (before == 'unsupported') {
      debugPrint('⚠️ Push web: Notification API não suportada neste navegador');
      return false;
    }

    if (before != 'granted') {
      // API nativa — exigida por Chrome/Safari; só após gesto do usuário (botão).
      final browserResult = await requestWebNotificationPermission();
      debugPrint(
        '📬 Push web: resposta Notification.requestPermission: $browserResult',
      );

      if (browserResult != 'granted') {
        debugPrint(
          '⚠️ Push web: permissão negada ($browserResult) — '
          'libere em Configurações do site se estiver bloqueado',
        );
        return false;
      }
    } else {
      debugPrint(
        '📬 Push web: permissão já granted — obtendo token (gesto do usuário)',
      );
    }

    final messaging = FirebaseMessaging.instance;

    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        await ensureFcmServiceWorkerReady();
        if (attempt > 1) {
          await Future.delayed(Duration(milliseconds: 400 * attempt));
        }
        _currentToken = await messaging.getToken(vapidKey: _webVapidKey);
        if (_currentToken != null && _currentToken!.isNotEmpty) {
          debugPrint(
            '✅ Push web: token FCM obtido (${_currentToken!.substring(0, 12)}...)',
          );
          await _persistWebToken(_currentToken!);
          await registerTokenWithBackend();
          return true;
        }
        lastError = 'token vazio';
      } catch (e) {
        lastError = e;
        debugPrint('⚠️ Push web: getToken tentativa $attempt/3 — $e');
      }
    }

    debugPrint(
      '⚠️ Push web: falha ao obter token — $lastError '
      '(confira firebase-messaging-sw.js e build com --pwa-strategy=none)',
    );
    return false;
  }

  Future<void> _initLocalNotificationsMobile() async {
    const androidInit = AndroidInitializationSettings('@drawable/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          _navigateFromPayload(payload);
        }
      },
    );
  }

  void _navigateFromPayload(String payload) {
    final parts = payload.split('|');
    if (parts.length >= 2) {
      navigateForPushTipo(parts[0], parts[1]);
    }
  }

  void _handleRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final tipo = data['tipo'] as String?;
    final referenciaId = data['referencia_id'] as String?;
    if (tipo != null) {
      navigateForPushTipo(tipo, referenciaId);
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    final tipo = data['tipo'] as String? ?? '';
    final referenciaId = data['referencia_id'] as String? ?? '';

    if (kIsWeb) {
      if (notification != null) {
        showWebForegroundNotification(
          title: notification.title ?? 'Permuta Policial',
          body: notification.body,
          data: {
            if (tipo.isNotEmpty) 'tipo': tipo,
            if (referenciaId.isNotEmpty) 'referencia_id': referenciaId,
          },
        );
      }
      return;
    }

    if (notification == null) return;

    final payload = tipo.isNotEmpty ? '$tipo|$referenciaId' : null;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'permuta_policial_default',
        'Permuta Policial',
        channelDescription: 'Notificações do app',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: payload,
    );
  }

  Future<void> registerTokenWithBackend() async {
    if (!_initialized || _currentToken == null) return;
    try {
      final platform = kIsWeb
          ? 'web'
          : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
      await _apiClient.post('/api/push/register', {
        'token': _currentToken,
        'platform': platform,
      });
      if (kIsWeb) {
        await _persistWebToken(_currentToken!);
      }
      debugPrint('✅ Push: token registrado no backend (platform=$platform)');
    } catch (e) {
      debugPrint('⚠️ Falha ao registrar token push: $e');
    }
  }

  Future<void> unregisterToken() async {
    if (_currentToken == null) return;
    try {
      await _apiClient.post('/api/push/unregister', {'token': _currentToken});
    } catch (_) {}
    _currentToken = null;
    await _clearWebTokenPrefs();
  }
}
