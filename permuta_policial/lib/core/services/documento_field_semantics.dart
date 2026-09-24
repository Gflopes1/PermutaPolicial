/// Heurísticas para distinguir nome de pessoa vs posto/graduação no OCR.
class DocumentoFieldSemantics {
  DocumentoFieldSemantics._();

  static const _rankKeywords = [
    'soldado',
    'cabo',
    'sargento',
    'subtenente',
    'tenente',
    'capitao',
    'capitão',
    'major',
    'coronel',
    'general',
    'aspirante',
    'aluno',
    'cadete',
    'delegado',
    'agente',
    'escrivao',
    'escrivão',
    'inspetor',
    'perito',
    '1º',
    '2º',
    '3º',
    '1o',
    '2o',
    '3o',
    'posto',
    'graduacao',
    'graduação',
  ];

  static bool looksLikeRank(String text) {
    final normalized = text.toLowerCase().trim();
    if (normalized.isEmpty) return false;
    return _rankKeywords.any((keyword) => normalized.contains(keyword));
  }

  static bool looksLikePersonName(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zà-ÿ\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return false;
    if (looksLikeRank(text)) return false;

    final words = normalized.split(' ').where((w) => w.length > 1).toList();
    if (words.length < 2) return false;

    final letterRatio = normalized.replaceAll(' ', '').length;
    return letterRatio >= 6;
  }

  static bool isValidForField({
    required String value,
    required bool isNome,
    required bool isCargo,
  }) {
    if (isNome) {
      return looksLikePersonName(value) || !looksLikeRank(value);
    }
    if (isCargo) {
      if (looksLikeRank(value)) return true;
      return !looksLikePersonName(value);
    }
    return true;
  }
}
