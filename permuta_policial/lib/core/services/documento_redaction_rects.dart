import 'dart:ui';

import 'documento_anchor_extractor.dart';
import 'verificacao_ocr_redaction.dart';

/// Calcula retângulos de redação ajustados ao conteúdo sensível — evita tarjas
/// grandes demais que cobrem rótulos ou texto relevante.
class DocumentoRedactionRects {
  DocumentoRedactionRects._();

  static final _cpfPattern = RegExp(r'\d{3}\.\d{3}\.\d{3}-\d{2}');
  static final _moneyPattern = RegExp(r'R\$\s?[\d.,]+', caseSensitive: false);
  static final _bankPattern = RegExp(
    r'(ag[eê]ncia|conta|banco|pix)\s*[:\-]?\s*[\d./\-Xx]+',
    caseSensitive: false,
  );
  static final _digitPattern = RegExp(r'\d');

  static List<Rect> compute({
    required List<OcrTextBlock> blocks,
    List<({String text, Rect rect})> words = const [],
  }) {
    final rects = <Rect>[];
    final coveredWords = <int>{};

    for (final block in blocks.where((b) => b.category == OcrBlockCategory.sensitive)) {
      if (_isLabelOnly(block.text)) continue;

      final blockWordIndices = _wordIndicesInBlock(block, words);
      final sensitiveWordRects = <Rect>[];

      for (final index in blockWordIndices) {
        final word = words[index];
        if (_isLabelOnly(word.text)) continue;
        if (_isSensitiveFragment(word.text)) {
          sensitiveWordRects.add(_tighten(word.rect));
          coveredWords.add(index);
        }
      }

      if (sensitiveWordRects.isNotEmpty) {
        rects.addAll(sensitiveWordRects);
        continue;
      }

      final subRects = _patternSubRects(block);
      if (subRects.isNotEmpty) {
        rects.addAll(subRects.map(_tighten));
        continue;
      }

      rects.add(_tighten(block.rect));
    }

    for (var i = 0; i < words.length; i++) {
      if (coveredWords.contains(i)) continue;
      final word = words[i];
      if (_isLabelOnly(word.text)) continue;
      if (VerificacaoOcrRedaction.classifyBlock(word.text) ==
          OcrBlockCategory.sensitive) {
        rects.add(_tighten(word.rect));
      }
    }

    return _consolidate(rects);
  }

  static bool _isLabelOnly(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return true;
    if (_isSensitiveFragment(trimmed)) return false;
    if (_digitPattern.hasMatch(trimmed)) return false;
    return DocumentoAnchorExtractor.matchesAnyKnownLabel(trimmed);
  }

  static bool _isSensitiveFragment(String text) {
    return _cpfPattern.hasMatch(text) ||
        _moneyPattern.hasMatch(text) ||
        _bankPattern.hasMatch(text);
  }

  static List<int> _wordIndicesInBlock(
    OcrTextBlock block,
    List<({String text, Rect rect})> words,
  ) {
    final indices = <int>[];
    for (var i = 0; i < words.length; i++) {
      if (_rectContainsPoint(block.rect, words[i].rect.center)) {
        indices.add(i);
      }
    }
    return indices;
  }

  static bool _rectContainsPoint(Rect outer, Offset point) {
    return point.dx >= outer.left &&
        point.dx <= outer.right &&
        point.dy >= outer.top &&
        point.dy <= outer.bottom;
  }

  static List<Rect> _patternSubRects(OcrTextBlock block) {
    final text = block.text;
    final rects = <Rect>[];

    for (final pattern in [_cpfPattern, _moneyPattern, _bankPattern]) {
      for (final match in pattern.allMatches(text)) {
        rects.add(
          _proportionalSubRect(
            block.rect,
            text.length,
            match.start,
            match.end,
          ),
        );
      }
    }

    return rects;
  }

  static Rect _proportionalSubRect(
    Rect lineRect,
    int textLength,
    int start,
    int end,
  ) {
    if (textLength <= 0) return _tighten(lineRect);
    final startRatio = start / textLength;
    final endRatio = end / textLength;
    return Rect.fromLTRB(
      lineRect.left + lineRect.width * startRatio,
      lineRect.top,
      lineRect.left + lineRect.width * endRatio,
      lineRect.bottom,
    );
  }

  static Rect _tighten(Rect rect) {
    if (rect.width <= 0 || rect.height <= 0) return rect;

    final vCrop = rect.height * 0.1;
    const hPad = 1.0;

    return Rect.fromLTRB(
      rect.left + hPad,
      rect.top + vCrop,
      rect.right - hPad,
      rect.bottom - vCrop,
    );
  }

  /// Agrupa retângulos sobrepostos e mantém o menor de cada grupo.
  static List<Rect> _consolidate(List<Rect> rects) {
    if (rects.isEmpty) return rects;

    final remaining = [...rects];
    final result = <Rect>[];

    while (remaining.isNotEmpty) {
      final seed = remaining.removeAt(0);
      final cluster = [seed];

      remaining.removeWhere((rect) {
        final overlaps = cluster.any((c) => _overlapRatio(c, rect) > 0.3);
        if (overlaps) cluster.add(rect);
        return overlaps;
      });

      cluster.sort(
        (a, b) => (a.width * a.height).compareTo(b.width * b.height),
      );
      result.add(cluster.first);
    }

    return result;
  }

  static double _overlapRatio(Rect a, Rect b) {
    final intersection = Rect.fromLTRB(
      a.left > b.left ? a.left : b.left,
      a.top > b.top ? a.top : b.top,
      a.right < b.right ? a.right : b.right,
      a.bottom < b.bottom ? a.bottom : b.bottom,
    );
    if (intersection.width <= 0 || intersection.height <= 0) return 0;

    final intersectionArea = intersection.width * intersection.height;
    final minArea = [
      a.width * a.height,
      b.width * b.height,
    ].reduce((x, y) => x < y ? x : y);

    if (minArea <= 0) return 0;
    return intersectionArea / minArea;
  }
}
