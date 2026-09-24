// /lib/core/api/http_client_factory_web.dart

import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';

http.Client createClient(Duration timeout) {
  final client = BrowserClient();
  client.withCredentials = true;
  return client;
}

