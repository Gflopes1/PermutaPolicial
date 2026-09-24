// /lib/core/utils/platform_utils.dart
// Arquivo genérico que o app vai importar
// Usa import condicional para escolher a implementação correta

import 'platform_utils_stub.dart'
    if (dart.library.js_interop) 'platform_utils_web.dart' as platform_utils_impl;

/// Retorna a URL atual (href)
String getUrl() => platform_utils_impl.getUrl();

/// Retorna o hostname atual
String getHost() => platform_utils_impl.getHost();

/// Retorna o pathname atual
String getPathname() => platform_utils_impl.getPathname();

/// Retorna os query parameters da URL (search)
String getSearch() => platform_utils_impl.getSearch();

/// Substitui o estado do histórico
void replaceHistoryState(String url) => platform_utils_impl.replaceHistoryState(url);

