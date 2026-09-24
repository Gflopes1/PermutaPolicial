/// Helpers para valores vindos da API (MySQL costuma retornar 0/1 em vez de bool).
bool parseApiBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is num) return value == 1;
  if (value is String) {
    final v = value.toLowerCase();
    return v == 'true' || v == '1';
  }
  return false;
}

/// Nome exibido ao abrir conversa iniciada a partir de permuta/mapa.
String chatConversaDisplayName(
  Map<String, dynamic> conversa,
  int destinatarioId,
) {
  final isAnonima = parseApiBool(conversa['anonima']);
  final remetenteRevelado = parseApiBool(conversa['remetente_revelado']);
  final iniciadaPor = conversa['iniciada_por'];

  if (isAnonima && !remetenteRevelado && iniciadaPor == destinatarioId) {
    return 'Usuário não identificado';
  }
  return conversa['outro_usuario_nome']?.toString() ?? 'Usuário';
}
