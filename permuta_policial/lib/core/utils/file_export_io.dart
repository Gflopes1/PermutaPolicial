import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportTextFile(String filename, String content) async {
  await exportBytesFile(
    filename,
    utf8.encode(content),
    mimeType: 'application/json',
  );
}

Future<void> exportBytesFile(String filename, List<int> bytes, {String mimeType = 'application/octet-stream'}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: mimeType, name: filename)],
    ),
  );
}
