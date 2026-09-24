import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:permuta_policial/core/services/documento_ocr_corpus.dart';
import 'package:permuta_policial/core/services/documento_ocr_types.dart';
import 'package:permuta_policial/core/services/verificacao_ocr_redaction.dart';

void main() {
  test('fromResult inclui blocos quando visionRawText está vazio', () {
    final result = DocumentoOcrResult(
      auditBytes: Uint8List(0),
      fields: ExtractedVerificationFields(nome: 'JOSE DA SILVA', matricula: '1234567'),
      blocks: [
        OcrTextBlock(
          text: 'Id Funcional 123456789012',
          rect: Rect.fromLTWH(0, 0, 10, 10),
          category: OcrBlockCategory.matricula,
        ),
      ],
    );

    final corpus = DocumentoOcrCorpus.fromResult(result);
    expect(corpus, contains('JOSE DA SILVA'));
    expect(corpus, contains('Id Funcional 123456789012'));
  });
}
