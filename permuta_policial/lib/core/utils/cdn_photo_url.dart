import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

const _r2KeyPrefixes = [
  'mapa-tatico/',
  'marketplace/',
  'consultoria-juridica/',
  'profile-photos/',
];

/// Corrige URLs salvas com esquema malformado (ex.: `https//cdn...`).
String _normalizeScheme(String path) {
  final trimmed = path.trim();
  if (trimmed.startsWith('https//')) {
    return 'https://${trimmed.substring(7)}';
  }
  if (trimmed.startsWith('http//')) {
    return 'http://${trimmed.substring(6)}';
  }
  return trimmed;
}

bool _isAbsoluteUrl(String path) {
  return path.startsWith('http://') || path.startsWith('https://');
}

bool _isCdnHost(String host) {
  final normalized = host.toLowerCase();
  return normalized.startsWith('cdn.') ||
      normalized.contains('r2.cloudflarestorage.com');
}

bool _isR2Key(String path) {
  return _r2KeyPrefixes.any((prefix) => path.startsWith(prefix));
}

String _cdnProxyUrl(String key) {
  var normalizedKey = key;
  if (normalizedKey.startsWith('/')) {
    normalizedKey = normalizedKey.substring(1);
  }
  if (normalizedKey.isEmpty) return '';
  return '${AppConfig.apiBaseUrl}/api/cdn?key=${Uri.encodeQueryComponent(normalizedKey)}';
}

/// Resolve URL de imagem armazenada no R2/CDN para exibição no app.
///
/// Na web, imagens do CDN passam pelo proxy `/api/cdn` da API (mesma origem),
/// evitando CORS e carregamento infinito do `CachedNetworkImage`.
String resolveCdnPhotoUrl(String? path) {
  if (path == null || path.isEmpty) return '';

  final normalized = _normalizeScheme(path);

  if (_isAbsoluteUrl(normalized)) {
    if (!kIsWeb) return normalized;

    final uri = Uri.tryParse(normalized);
    if (uri == null || !_isCdnHost(uri.host)) return normalized;

    var key = uri.path;
    if (key.startsWith('/')) key = key.substring(1);
    if (key.isEmpty) return normalized;

    return _cdnProxyUrl(key);
  }

  if (normalized.startsWith('/')) {
    final key = normalized.substring(1);
    if (_isR2Key(key)) return _cdnProxyUrl(key);
    return '${AppConfig.apiBaseUrl}$normalized';
  }

  if (_isR2Key(normalized)) return _cdnProxyUrl(normalized);

  return '${AppConfig.apiBaseUrl}/$normalized';
}
