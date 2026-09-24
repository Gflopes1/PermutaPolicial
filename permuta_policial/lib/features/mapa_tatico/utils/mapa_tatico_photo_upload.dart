import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

/// Monta [MultipartFile] com MIME correto para upload de foto no mapa tático.
http.MultipartFile buildMapaTaticoPhotoMultipart(
  List<int> bytes, {
  String? filename,
  String field = 'photos',
}) {
  final name = filename?.trim().isNotEmpty == true ? filename!.trim() : 'photo.jpg';
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';

  final contentType = switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' || 'heif' => 'image/heic',
    _ => 'image/jpeg',
  };

  return http.MultipartFile.fromBytes(
    field,
    bytes,
    filename: name.endsWith('.') ? '${name}jpg' : (name.contains('.') ? name : '$name.jpg'),
    contentType: MediaType.parse(contentType),
  );
}

const kMapaTaticoMaxPhotos = 10;

Future<List<http.MultipartFile>> buildMapaTaticoPhotosFromXFiles(List<XFile> files) async {
  final limited = files.take(kMapaTaticoMaxPhotos).toList();
  final parts = <http.MultipartFile>[];
  for (final file in limited) {
    final bytes = await file.readAsBytes();
    parts.add(buildMapaTaticoPhotoMultipart(bytes, filename: file.name));
  }
  return parts;
}
