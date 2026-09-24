import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> exportTextFile(String filename, String content) async {
  await exportBytesFile(filename, utf8.encode(content), mimeType: 'application/json;charset=utf-8');
}

Future<void> exportBytesFile(String filename, List<int> bytes, {String mimeType = 'application/octet-stream'}) async {
  final data = Uint8List.fromList(bytes);
  final blob = web.Blob(
    [data.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
