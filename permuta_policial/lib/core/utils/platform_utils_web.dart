// /lib/core/utils/platform_utils_web.dart
// Implementação Real para Web (usa package:web)

import 'package:web/web.dart' as web;

/// Retorna a URL atual (href)
String getUrl() => web.window.location.href;

/// Retorna o hostname atual
String getHost() => web.window.location.hostname;

/// Retorna o pathname atual
String getPathname() => web.window.location.pathname;

/// Retorna os query parameters da URL (search)
String getSearch() => web.window.location.search;

/// Substitui o estado do histórico
void replaceHistoryState(String url) {
  web.window.history.replaceState(null, '', url);
}

