/// Comparação permissiva entre cadastro e texto OCR.
///
/// Regra: se o valor esperado estiver presente no que foi lido (ignorando
/// pontuação, espaços e maiúsculas/minúsculas), considera correspondência.
class DocumentoFieldMatch {
  DocumentoFieldMatch._();

  static String normalizeLoose(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãä]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static String normalizeName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãä]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Iterable<String> _sources(String? extracted, String? ocrCorpus) sync* {
    if (extracted?.trim().isNotEmpty == true) yield extracted!.trim();
    if (ocrCorpus?.trim().isNotEmpty == true) yield ocrCorpus!.trim();
  }

  static bool nomePresent({
    required String? expected,
    String? extracted,
    String? ocrCorpus,
  }) {
    final exp = normalizeName(expected ?? '');
    if (exp.isEmpty) return false;

    for (final src in _sources(extracted, ocrCorpus)) {
      final norm = normalizeName(src);
      if (norm.isEmpty) continue;
      if (norm.contains(exp) || exp.contains(norm)) return true;

      final parts = exp.split(' ').where((p) => p.length > 2).toList();
      if (parts.length >= 2 && parts.every((p) => norm.contains(p))) return true;
    }
    return false;
  }

  static bool matriculaPresent({
    required String? expected,
    String? extracted,
    String? ocrCorpus,
  }) {
    final exp = normalizeLoose(expected ?? '');
    if (exp.length < 4) return false;

    for (final src in _sources(extracted, ocrCorpus)) {
      final norm = normalizeLoose(src);
      if (norm.isEmpty) continue;
      if (norm.contains(exp)) return true;
      if (exp.contains(norm) && norm.length >= 4) return true;
    }
    return false;
  }

  static bool forcaPresent({
    required String? expected,
    String? extracted,
    String? ocrCorpus,
  }) {
    final exp = normalizeLoose(expected ?? '');
    if (exp.isEmpty) return false;

    for (final src in _sources(extracted, ocrCorpus)) {
      final norm = normalizeLoose(src);
      if (norm.contains(exp) || exp.contains(norm)) return true;
    }
    return false;
  }

  static bool cargoPresent({String? extracted, String? ocrCorpus}) {
    for (final src in _sources(extracted, ocrCorpus)) {
      if (src.trim().length >= 3) return true;
    }
    return false;
  }
}
