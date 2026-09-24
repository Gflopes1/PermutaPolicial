import 'documento_ocr_types.dart';
import 'verificacao_ocr_redaction.dart';

/// Monta texto único para comparação permissiva (cadastro ⊆ OCR).
class DocumentoOcrCorpus {
  DocumentoOcrCorpus._();

  static String fromResult(DocumentoOcrResult result) {
    final parts = <String>[];

    final raw = result.visionRawText?.trim();
    if (raw != null && raw.isNotEmpty) parts.add(raw);

    for (final block in result.blocks) {
      final text = block.text.trim();
      if (text.isNotEmpty) parts.add(text);
    }

    for (final value in [
      result.fields.nome,
      result.fields.matricula,
      result.fields.forca,
      result.fields.cargo,
    ]) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) parts.add(text);
    }

    return parts.join('\n');
  }

  static String fromResults(Iterable<DocumentoOcrResult> results) {
    return results.map(fromResult).where((t) => t.trim().isNotEmpty).join('\n');
  }

  static String forSubmit({
    required Iterable<DocumentoOcrResult> results,
    ExtractedVerificationFields? mergedFields,
  }) {
    final parts = <String>[fromResults(results)];

    if (mergedFields != null) {
      for (final value in [
        mergedFields.nome,
        mergedFields.matricula,
        mergedFields.forca,
        mergedFields.cargo,
      ]) {
        final text = value?.trim();
        if (text != null && text.isNotEmpty) parts.add(text);
      }
    }

    return parts.where((p) => p.trim().isNotEmpty).join('\n');
  }
}
