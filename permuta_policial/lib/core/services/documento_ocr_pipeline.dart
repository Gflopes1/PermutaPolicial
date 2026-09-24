import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

import 'documento_anchor_extractor.dart';
import 'documento_ocr_types.dart';
import 'documento_preprocess_debug.dart';
import 'documento_redaction_rects.dart';
import 'verificacao_ocr_redaction.dart';

/// Camada agnóstica de plataforma: extração por âncoras, classificação e redação.
class DocumentoOcrPipeline {
  static AnchorExtractionResult extractFromLines(
    List<({String text, Rect rect})> lines, {
    String? forcaSigla,
    String? tipoDocumento,
    String? nomeCadastrado,
    String? matriculaCadastrada,
  }) {
    return DocumentoAnchorExtractor.extract(
      lines: lines,
      forcaSigla: forcaSigla,
      tipoDocumento: tipoDocumento,
      nomeCadastrado: nomeCadastrado,
      matriculaCadastrada: matriculaCadastrada,
    );
  }

  static List<Rect> rectsForRedaction(
    List<OcrTextBlock> lineBlocks, {
    List<({String text, Rect rect})> words = const [],
  }) {
    return DocumentoRedactionRects.compute(blocks: lineBlocks, words: words);
  }

  static DocumentoOcrResult buildResult({
    required img.Image decoded,
    required List<OcrTextBlock> blocks,
    required ExtractedVerificationFields fields,
    required Uint8List auditBytes,
    String? visionRawText,
    bool imageWasCompressed = false,
    String? originalImageSizeLabel,
    List<DocumentoPreprocessStep> preprocessSteps = const [],
  }) {
    return DocumentoOcrResult(
      auditBytes: auditBytes,
      fields: fields,
      blocks: blocks,
      visionRawText: visionRawText,
      imageWasCompressed: imageWasCompressed,
      originalImageSizeLabel: originalImageSizeLabel,
      preprocessSteps: preprocessSteps,
    );
  }

  static Uint8List redactWithImagePackage(
    img.Image decoded,
    List<OcrTextBlock> blocks, {
    List<({String text, Rect rect})> words = const [],
  }) {
    final rects = DocumentoRedactionRects.compute(blocks: blocks, words: words);
    return redactWithRects(decoded, rects);
  }

  static Uint8List redactWithRects(img.Image decoded, List<Rect> rects) {
    final copy = img.Image.from(decoded);
    for (final rect in rects) {
      final left = rect.left.clamp(0, copy.width - 1).round();
      final top = rect.top.clamp(0, copy.height - 1).round();
      final right = rect.right.clamp(0, copy.width).round();
      final bottom = rect.bottom.clamp(0, copy.height).round();
      if (right <= left || bottom <= top) continue;
      img.fillRect(
        copy,
        x1: left,
        y1: top,
        x2: right,
        y2: bottom,
        color: img.ColorRgb8(0, 0, 0),
      );
    }
    return VerificacaoOcrRedaction.encodeJpeg(copy);
  }
}
