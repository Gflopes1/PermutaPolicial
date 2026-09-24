import 'app_share_stub.dart'
    if (dart.library.js_interop) 'app_share_web.dart' as app_share_impl;

/// Compartilha [text] usando o mecanismo nativo da plataforma.
/// Em web sem suporte, copia para a área de transferência (retorna `false`).
Future<bool> shareText(String text, {String? subject}) =>
    app_share_impl.shareText(text, subject: subject);
