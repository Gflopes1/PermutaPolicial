import 'package:url_launcher/url_launcher.dart';

class VerificacaoWhatsappHelper {
  static const defaultNumero = '5551986200626';

  static Future<bool> openVerificationRequest({
    required String nome,
    required String idFuncional,
    String? contexto,
    String? numero,
  }) async {
    final mensagem = contexto != null && contexto.isNotEmpty
        ? 'olá, sou $nome, ID $idFuncional e preciso verificar minha conta para $contexto'
        : 'olá, sou $nome, ID $idFuncional e preciso verificar minha conta no Permuta Policial';
    final digits = (numero ?? defaultNumero).replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(mensagem)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
