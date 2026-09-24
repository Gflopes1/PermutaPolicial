import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:permuta_policial/core/services/documento_redaction_rects.dart';
import 'package:permuta_policial/core/services/verificacao_ocr_redaction.dart';

void main() {
  test('tarja em linha mista cobre só o valor sensível, não o rótulo', () {
    const lineRect = Rect.fromLTWH(50, 230, 170, 18);
    final blocks = [
      const OcrTextBlock(
        text: 'CPF 123.456.789-00',
        rect: lineRect,
        category: OcrBlockCategory.sensitive,
      ),
    ];
    final words = [
      (text: 'CPF', rect: const Rect.fromLTWH(50, 230, 30, 18)),
      (text: '123.456.789-00', rect: const Rect.fromLTWH(90, 230, 120, 18)),
    ];

    final rects = DocumentoRedactionRects.compute(blocks: blocks, words: words);

    expect(rects.length, 1);
    expect(rects.first.left, greaterThan(50));
    expect(rects.first.width, lessThan(lineRect.width));
    expect(rects.first.width, closeTo(120, 5));
  });

  test('rótulo isolado não gera tarja', () {
    final blocks = [
      const OcrTextBlock(
        text: 'CPF',
        rect: Rect.fromLTWH(50, 230, 40, 18),
        category: OcrBlockCategory.sensitive,
      ),
    ];

    final rects = DocumentoRedactionRects.compute(blocks: blocks);
    expect(rects, isEmpty);
  });

  test('consolida retângulos sobrepostos mantendo o menor', () {
    final blocks = [
      const OcrTextBlock(
        text: '123.456.789-00',
        rect: Rect.fromLTWH(100, 230, 120, 18),
        category: OcrBlockCategory.sensitive,
      ),
      const OcrTextBlock(
        text: '123.456.789-00',
        rect: Rect.fromLTWH(90, 220, 160, 40),
        category: OcrBlockCategory.sensitive,
      ),
    ];

    final rects = DocumentoRedactionRects.compute(blocks: blocks);

    expect(rects.length, 1);
    expect(rects.first.width * rects.first.height,
        lessThan(160.0 * 40.0));
  });
}
