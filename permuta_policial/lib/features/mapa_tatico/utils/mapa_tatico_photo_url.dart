import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';

/// Resolve URL de foto do mapa tático para exibição no app.
///
/// Na web, imagens do CDN passam pelo proxy `/api/cdn/...` da API (mesma origem),
/// evitando CORS e carregamento infinito do `CachedNetworkImage`.
String resolveMapaTaticoPhotoUrl(String? path) {
  if (path == null || path.isEmpty) return '';

  final String absoluteUrl;
  if (path.startsWith('http://') || path.startsWith('https://')) {
    absoluteUrl = path;
  } else {
    absoluteUrl = '${AppConfig.apiBaseUrl}$path';
  }

  if (!kIsWeb) return absoluteUrl;

  final uri = Uri.tryParse(absoluteUrl);
  if (uri == null) return absoluteUrl;

  final host = uri.host.toLowerCase();
  final isCdnHost =
      host.startsWith('cdn.') || host.contains('r2.cloudflarestorage.com');
  if (!isCdnHost) return absoluteUrl;

  var key = uri.path;
  if (key.startsWith('/')) key = key.substring(1);
  if (key.isEmpty) return absoluteUrl;

  // Query string em vez de path: evita que regras de estáticos do Nginx
  // (location ~* \.(jpg|png)$) interceptem a URL antes do proxy /api.
  return '${AppConfig.apiBaseUrl}/api/cdn?key=${Uri.encodeQueryComponent(key)}';
}
