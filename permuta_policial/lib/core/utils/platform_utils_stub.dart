// /lib/core/utils/platform_utils_stub.dart
// Implementação "Falsa" para Mobile (Android/iOS) - não usa package:web

/// Retorna a URL atual (vazio no mobile, pois não há URL de navegador)
String getUrl() => '';

/// Retorna o hostname atual (vazio no mobile)
String getHost() => '';

/// Retorna o pathname atual (vazio no mobile)
String getPathname() => '';

/// Retorna os query parameters da URL (vazio no mobile)
String getSearch() => '';

/// Substitui o estado do histórico (no-op no mobile)
void replaceHistoryState(String url) {
  // No-op no mobile
}

