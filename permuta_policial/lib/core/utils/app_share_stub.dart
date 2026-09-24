import 'package:share_plus/share_plus.dart';

/// Compartilha [text] via sheet nativo do sistema.
/// Retorna `true` se o compartilhamento foi iniciado/concluído.
Future<bool> shareText(String text, {String? subject}) async {
  final result = await SharePlus.instance.share(
    ShareParams(text: text, subject: subject),
  );
  return result.status != ShareResultStatus.dismissed;
}
