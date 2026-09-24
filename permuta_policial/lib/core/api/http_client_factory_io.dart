// /lib/core/api/http_client_factory_io.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../config/api_certificate_pins.dart';

http.Client createClient(Duration timeout) {
  // Sem roots do SO, toda conexão TLS passa por badCertificateCallback e o pin é validado.
  final httpClient = ApiCertificatePins.isEnabled
      ? HttpClient(context: SecurityContext(withTrustedRoots: false))
      : HttpClient();
  httpClient.connectionTimeout = timeout;

  if (ApiCertificatePins.isEnabled) {
    httpClient.badCertificateCallback = (cert, host, port) {
      return ApiCertificatePins.verify(cert, host);
    };
  }

  return IOClient(httpClient);
}
