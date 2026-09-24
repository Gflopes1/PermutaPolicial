import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

import 'device_info_models.dart';

DeviceInfoSnapshot getDeviceInfo() {
  if (kIsWeb) {
    return const DeviceInfoSnapshot(
      dispositivoTipo: 'web',
      navegador: 'web',
      sistemaOperacional: 'web',
    );
  }
  try {
    if (Platform.isAndroid) {
      return const DeviceInfoSnapshot(
        dispositivoTipo: 'mobile',
        navegador: 'app',
        sistemaOperacional: 'android',
      );
    }
    if (Platform.isIOS) {
      return const DeviceInfoSnapshot(
        dispositivoTipo: 'mobile',
        navegador: 'app',
        sistemaOperacional: 'ios',
      );
    }
  } catch (_) {}
  return const DeviceInfoSnapshot(
    dispositivoTipo: 'desktop',
    navegador: 'app',
    sistemaOperacional: 'unknown',
  );
}
