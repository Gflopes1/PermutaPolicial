import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'app_config.dart';

/// Pins SHA-256 (DER do certificado) para API em release mobile.
///
/// Atualize o hash via openssl (DER SHA-256 base64) após rotação de certificado.
class ApiCertificatePins {
  ApiCertificatePins._();

  static const bool _pinningFlag =
      bool.fromEnvironment('CERT_PINNING', defaultValue: true);

  /// Hashes base64 SHA-256 do certificado (DER). Inclua backup antes de rotação.
  static const List<String> _productionPins = [
    // br.permutapolicial.com.br (Cloudflare) — atualize após rotação de cert
    String.fromEnvironment('CERT_PIN_PROD', defaultValue: ''),
  ];

  static const List<String> _developmentPins = [
    String.fromEnvironment('CERT_PIN_DEV', defaultValue: ''),
  ];

  static bool get isEnabled =>
      !AppConfig.isDevelopment && _pinningFlag && _activePins.isNotEmpty;

  static List<String> get _activePins {
    final pins = AppConfig.isProduction ? _productionPins : _developmentPins;
    return pins.where((p) => p.trim().isNotEmpty).toList();
  }

  static bool verify(X509Certificate cert, String host) {
    if (!isEnabled) return true;

    final allowedHosts = {
      'br.permutapolicial.com.br',
      'dev.br.permutapolicial.com.br',
    };
    if (!allowedHosts.contains(host.toLowerCase())) {
      return false;
    }

    final hash = base64.encode(sha256.convert(cert.der).bytes);
    return _activePins.contains(hash);
  }
}
