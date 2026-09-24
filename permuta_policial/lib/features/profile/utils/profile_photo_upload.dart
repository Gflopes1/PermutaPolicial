import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

http.MultipartFile buildProfilePhotoMultipart(List<int> bytes, {String? filename}) {
  final name = filename?.trim().isNotEmpty == true ? filename!.trim() : 'photo.jpg';
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';

  final contentType = switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' || 'heif' => 'image/heic',
    _ => 'image/jpeg',
  };

  return http.MultipartFile.fromBytes(
    'photo',
    bytes,
    filename: name.contains('.') ? name : '$name.jpg',
    contentType: MediaType.parse(contentType),
  );
}
