// /lib/core/utils/pwa_utils.dart
// Arquivo genérico que o app vai importar
// Usa import condicional para escolher a implementação correta

import 'pwa_utils_stub.dart'
    if (dart.library.js_interop) 'pwa_utils_web.dart' as pwa_utils_impl;

/// Detecta se está rodando como PWA (Progressive Web App)
/// Retorna true se o app está rodando em modo standalone, fullscreen ou minimal-ui
bool isPWA() => pwa_utils_impl.isPWA();

