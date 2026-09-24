import 'dart:ui';



import 'package:flutter_test/flutter_test.dart';

import 'package:image/image.dart' as img;

import 'package:permuta_policial/core/services/documento_anchor_extractor.dart';

import 'package:permuta_policial/core/services/documento_ocr_pipeline.dart';

import 'package:permuta_policial/core/services/verificacao_ocr_redaction.dart';



void main() {

  test('classifica blocos sensíveis sem armazenar CPF', () {

    expect(

      VerificacaoOcrRedaction.classifyBlock('Salário líquido R\$ 4.532,18'),

      OcrBlockCategory.sensitive,

    );

    expect(

      VerificacaoOcrRedaction.classifyBlock('CPF 123.456.789-00'),

      OcrBlockCategory.sensitive,

    );

    expect(

      VerificacaoOcrRedaction.classifyBlock('Texto comum'),

      OcrBlockCategory.other,

    );

  });



  test('redação cobre pixels sensíveis antes do upload', () {

    final source = img.Image(width: 400, height: 300);

    img.fill(source, color: img.ColorRgb8(240, 240, 240));



    final sensitiveBlock = OcrTextBlock(

      text: 'R\$ 9.999,99',

      rect: const Rect.fromLTWH(40, 50, 120, 30),

      category: OcrBlockCategory.sensitive,

    );



    final redacted = VerificacaoOcrRedaction.redactImage(source, [sensitiveBlock]);

    final redactedBytes = VerificacaoOcrRedaction.encodeJpeg(redacted);



    expect(

      VerificacaoOcrRedaction.sensitiveRegionsAreRedacted(

        redactedBytes,

        [sensitiveBlock],

      ),

      isTrue,

    );

  });



  test('palavras sensíveis em linha mista entram na redação ajustada', () {
    final blocks = [
      OcrTextBlock(
        text: 'Salário R\$ 4.532,18',
        rect: const Rect.fromLTWH(10, 10, 140, 12),
        category: OcrBlockCategory.sensitive,
      ),
    ];
    final words = [
      (text: 'Salário', rect: const Rect.fromLTWH(10, 10, 50, 12)),
      (text: 'R\$ 4.532,18', rect: const Rect.fromLTWH(70, 10, 80, 12)),
    ];

    final rects = DocumentoOcrPipeline.rectsForRedaction(blocks, words: words);
    expect(rects.length, 1);
    expect(rects.first.width, lessThan(140));
    expect(rects.first.left, greaterThanOrEqualTo(70));
  });



  test('payload de upload não inclui campos de CPF', () {

    final fields = ExtractedVerificationFields(

      nome: 'João Silva',

      matricula: '1234567',

      forca: 'PMESP',

      cargo: 'Soldado',

    );



    final payload = fields.toPayload('funcional');

    expect(payload.containsKey('cpf'), isFalse);

    expect(payload.containsKey('cpf_extraido'), isFalse);

    expect(payload['nome_extraido'], 'João Silva');

    expect(payload['matricula_extraida'], '1234567');

  });



  test('extração por âncora BM-RS extrai campos de verificação e oculta sensíveis', () {

    final lines = [

      (text: 'BRIGADA MILITAR', rect: const Rect.fromLTWH(50, 10, 200, 20)),

      (text: 'CARTEIRA DE IDENTIDADE FUNCIONAL', rect: const Rect.fromLTWH(50, 35, 300, 20)),

      (text: 'Portador', rect: const Rect.fromLTWH(50, 80, 80, 18)),

      (text: 'JOSE DA SILVA SANTOS', rect: const Rect.fromLTWH(50, 100, 250, 18)),

      (text: 'Posto/Graduação', rect: const Rect.fromLTWH(50, 130, 120, 18)),

      (text: 'Soldado PM', rect: const Rect.fromLTWH(50, 150, 120, 18)),

      (text: 'Id. Funcional', rect: const Rect.fromLTWH(50, 200, 100, 18)),

      (text: '123456', rect: const Rect.fromLTWH(160, 200, 80, 18)),

      (text: 'CPF', rect: const Rect.fromLTWH(50, 230, 40, 18)),

      (text: '123.456.789-00', rect: const Rect.fromLTWH(100, 230, 120, 18)),

      (text: 'Filiação', rect: const Rect.fromLTWH(50, 260, 70, 18)),

      (text: 'MARIA SILVA', rect: const Rect.fromLTWH(50, 280, 150, 18)),

      (text: 'JOSE SANTOS', rect: const Rect.fromLTWH(50, 300, 150, 18)),

    ];



    final result = DocumentoAnchorExtractor.extract(

      lines: lines,

      forcaSigla: 'BMRS',

      tipoDocumento: 'funcional',

    );



    expect(result.fields.nome, 'JOSE DA SILVA SANTOS');

    expect(result.fields.cargo, 'Soldado PM');

    expect(result.fields.matricula, '123456');

    expect(result.fields.forca, 'BMRS');

    expect(result.matchedConfig?.id, 'bmrs_funcional');



    final cpfBlock = result.blocks.firstWhere((b) => b.text == '123.456.789-00');

    expect(cpfBlock.category, OcrBlockCategory.sensitive);



    final filiacaoBlock = result.blocks.firstWhere((b) => b.text == 'MARIA SILVA');

    expect(filiacaoBlock.category, OcrBlockCategory.sensitive);



    expect(result.fields.toPayload('funcional').containsKey('cpf'), isFalse);

  });



  test('extração por âncora PMESP usa configuração diferente do BM-RS', () {

    final lines = [

      (text: 'POLÍCIA MILITAR DO ESTADO DE SAO PAULO', rect: const Rect.fromLTWH(40, 10, 320, 20)),

      (text: 'Nome', rect: const Rect.fromLTWH(40, 60, 60, 18)),

      (text: 'CARLOS ALBERTO LIMA', rect: const Rect.fromLTWH(40, 80, 220, 18)),

      (text: 'Matrícula', rect: const Rect.fromLTWH(40, 110, 90, 18)),

      (text: '9876543', rect: const Rect.fromLTWH(140, 110, 80, 18)),

      (text: 'Posto', rect: const Rect.fromLTWH(40, 140, 60, 18)),

      (text: 'Cabo PM', rect: const Rect.fromLTWH(40, 160, 90, 18)),

    ];



    final result = DocumentoAnchorExtractor.extract(

      lines: lines,

      tipoDocumento: 'funcional',

    );



    expect(result.matchedConfig?.id, 'pmesp_funcional');

    expect(result.fields.nome, 'CARLOS ALBERTO LIMA');

    expect(result.fields.matricula, '9876543');

    expect(result.fields.cargo, 'Cabo PM');

    expect(result.fields.forca, 'PMESP');

  });



  test('rótulo Id Funcional tolera erro comum de OCR (ld.)', () {

    expect(

      DocumentoAnchorExtractor.matchesLabel('ld. Funcional', ['Id. Funcional']),

      isTrue,

    );

  });

}


