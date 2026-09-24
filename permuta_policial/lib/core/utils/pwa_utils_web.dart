// /lib/core/utils/pwa_utils_web.dart
// Implementação Real para Web (usa package:web)

import 'package:web/web.dart' as web;

/// Detecta se está rodando como PWA
/// Verifica display-mode: standalone, fullscreen ou minimal-ui
bool isPWA() {
  try {
    final isStandalone = web.window.matchMedia('(display-mode: standalone)').matches ||
                        web.window.matchMedia('(display-mode: fullscreen)').matches ||
                        web.window.matchMedia('(display-mode: minimal-ui)').matches;
    
    return isStandalone;
  } catch (e) {
    // Em caso de erro, retorna false
    return false;
  }
}

