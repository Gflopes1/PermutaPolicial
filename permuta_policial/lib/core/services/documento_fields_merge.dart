import 'documento_field_semantics.dart';
import 'verificacao_ocr_redaction.dart';

/// Fusão de campos vindos de fontes diferentes: motores de OCR (Tesseract e
/// Google Vision) e faces distintas do documento (frente vertical, verso
/// horizontal), onde cada face só contém parte dos dados.
class DocumentoFieldsMerge {
  DocumentoFieldsMerge._();

  static ExtractedVerificationFields merge(
    List<ExtractedVerificationFields?> sources, {
    String? forcaSigla,
    String? nomeCadastrado,
    String? matriculaCadastrada,
  }) {
    final present = sources.whereType<ExtractedVerificationFields>().toList();
    if (present.isEmpty) return const ExtractedVerificationFields();

    return ExtractedVerificationFields(
      nome: pickNome(
        present.map((f) => f.nome).toList(),
        nomeCadastrado: nomeCadastrado,
      ),
      matricula: pickMatricula(
        present.map((f) => f.matricula).toList(),
        forcaSigla: forcaSigla,
        matriculaCadastrada: matriculaCadastrada,
      ),
      cargo: pickCargo(present.map((f) => f.cargo).toList()),
      forca: pickForca(present.map((f) => f.forca).toList()),
    );
  }

  static List<String> _clean(List<String?> values) {
    return values
        .whereType<String>()
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
  }

  static String? pickNome(List<String?> values, {String? nomeCadastrado}) {
    final candidates = _clean(values)
        .where((v) => !DocumentoFieldSemantics.looksLikeRank(v))
        .toList();
    if (candidates.isEmpty) return null;

    if (nomeCadastrado != null && nomeCadastrado.trim().isNotEmpty) {
      final hint = nomeCadastrado.trim().toLowerCase();
      for (final value in candidates) {
        final lower = value.toLowerCase();
        if (hint.contains(lower) || lower.contains(hint)) return value;
      }
    }

    final nameLike =
        candidates.where(DocumentoFieldSemantics.looksLikePersonName).toList();
    final pool = nameLike.isNotEmpty ? nameLike : candidates;
    pool.sort((a, b) => b.length.compareTo(a.length));
    return pool.first;
  }

  static String? pickMatricula(
    List<String?> values, {
    String? forcaSigla,
    String? matriculaCadastrada,
  }) {
    final candidates = _clean(values);
    if (candidates.isEmpty) return null;

    if (matriculaCadastrada != null && matriculaCadastrada.trim().isNotEmpty) {
      final target = _digits(matriculaCadastrada);
      for (final value in candidates) {
        final digits = _digits(value);
        if (digits.isEmpty || target.isEmpty) continue;
        if (digits.contains(target)) return value;
      }
    }

    return candidates.first;
  }

  static String? pickCargo(List<String?> values) {
    final candidates = _clean(values);
    if (candidates.isEmpty) return null;

    for (final value in candidates) {
      if (DocumentoFieldSemantics.looksLikeRank(value)) return value;
    }
    for (final value in candidates) {
      if (!DocumentoFieldSemantics.looksLikePersonName(value)) return value;
    }
    return null;
  }

  static String? pickForca(List<String?> values) {
    final candidates = _clean(values);
    return candidates.isEmpty ? null : candidates.first;
  }

  static String _digits(String value) => value.replaceAll(RegExp(r'[.\-/\s]'), '');
}
