import 'package:web/web.dart' as web;

import 'device_info_models.dart';

DeviceInfoSnapshot getDeviceInfo() {
  final ua = web.window.navigator.userAgent;
  final lower = ua.toLowerCase();

  String dispositivoTipo = 'desktop';
  if (lower.contains('mobile') ||
      lower.contains('android') ||
      lower.contains('iphone') ||
      lower.contains('ipad')) {
    dispositivoTipo = 'mobile';
  } else if (lower.contains('tablet')) {
    dispositivoTipo = 'tablet';
  }

  String navegador = 'outro';
  if (lower.contains('edg/')) {
    navegador = 'edge';
  } else if (lower.contains('chrome/') && !lower.contains('edg/')) {
    navegador = 'chrome';
  } else if (lower.contains('firefox/')) {
    navegador = 'firefox';
  } else if (lower.contains('safari/') && !lower.contains('chrome/')) {
    navegador = 'safari';
  } else if (lower.contains('opr/') || lower.contains('opera')) {
    navegador = 'opera';
  }

  String sistemaOperacional = 'desconhecido';
  if (lower.contains('android')) {
    sistemaOperacional = 'android';
  } else if (lower.contains('iphone') || lower.contains('ipad') || lower.contains('ios')) {
    sistemaOperacional = 'ios';
  } else if (lower.contains('windows')) {
    sistemaOperacional = 'windows';
  } else if (lower.contains('mac os') || lower.contains('macintosh')) {
    sistemaOperacional = 'macos';
  } else if (lower.contains('linux')) {
    sistemaOperacional = 'linux';
  }

  return DeviceInfoSnapshot(
    dispositivoTipo: dispositivoTipo,
    navegador: navegador,
    sistemaOperacional: sistemaOperacional,
  );
}
