// Utilitários de Notification API no navegador.

import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'notification_navigation.dart';
String getWebNotificationPermission() {
  try {
    return web.Notification.permission;
  } catch (_) {
    return 'unsupported';
  }
}

Future<String> requestWebNotificationPermission() async {
  try {
    final result = await web.Notification.requestPermission().toDart;
    return result.toDart;
  } catch (_) {
    return 'denied';
  }
}

bool get isMobileWebBrowser {
  try {
    final ua = web.window.navigator.userAgent.toLowerCase();
    return ua.contains('mobile') ||
        ua.contains('android') ||
        ua.contains('iphone') ||
        ua.contains('ipad');
  } catch (_) {
    return false;
  }
}

bool get isSamsungBrowser {
  try {
    final ua = web.window.navigator.userAgent.toLowerCase();
    return ua.contains('samsungbrowser');
  } catch (_) {
    return false;
  }
}

bool get isIosWebBrowser {
  try {
    final ua = web.window.navigator.userAgent.toLowerCase();
    return ua.contains('iphone') ||
        ua.contains('ipad') ||
        (ua.contains('macintosh') && web.window.navigator.maxTouchPoints > 1);
  } catch (_) {
    return false;
  }
}

String? _routeForWebNotificationClick(Map<String, String>? data) {
  final tipo = data?['tipo'];
  if (tipo == null) return null;
  return staticRouteForNotificacaoTipo(
    tipo,
    int.tryParse(data?['referencia_id'] ?? ''),
  );
}

/// Exibe alerta nativo do navegador quando o app web está em primeiro plano.
void showWebForegroundNotification({
  required String title,
  String? body,
  Map<String, String>? data,
}) {
  if (getWebNotificationPermission() != 'granted') return;

  try {
    final options = web.NotificationOptions(
      body: body ?? '',
      icon: '/icons/Icon-192.png',
      tag: data?['tipo'] ?? 'permuta-foreground',
    );
    final notification = web.Notification(title, options);

    notification.onclick = ((web.Event event) {
      event.preventDefault();
      notification.close();
      final route = _routeForWebNotificationClick(data);
      if (route != null) {
        web.window.location.assign(route);
      }
    }).toJS;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ Web foreground notification: $e');
    }
  }
}
