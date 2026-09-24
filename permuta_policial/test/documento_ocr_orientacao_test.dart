import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:permuta_policial/core/services/documento_fields_merge.dart';
import 'package:permuta_policial/core/services/documento_ocr_orientacao.dart';
import 'package:permuta_policial/core/services/verificacao_ocr_redaction.dart';

Offset _rotateCw90(Offset p, int baseW) => Offset(p.dy, baseW - p.dx);

Rect _rotateRectCw90(Rect rect, int baseW) {
  final corners = [
    rect.topLeft,
    rect.topRight,
    rect.bottomLeft,
    rect.bottomRight,
  ].map((p) => _rotateCw90(p, baseW));

  var left = corners.first.dx;
  var top = corners.first.dy;
  var right = corners.first.dx;
  var bottom = corners.first.dy;
  for (final p in corners) {
    if (p.dx < left) left = p.dx;
    if (p.dy < top) top = p.dy;
    if (p.dx > right) right = p.dx;
    if (p.dy > bottom) bottom = p.dy;
  }
  return Rect.fromLTRB(left, top, right, bottom);
}

void main() {
  test('mapeia retângulo de 90° de volta à base', () {
    const baseW = 1000;
    const baseH = 800;

    const original = Rect.fromLTWH(100, 200, 150, 30);
    final rotated = _rotateRectCw90(original, baseW);

    final mapped = OcrOrientacaoMapper.mapRectToBase(
      rect: rotated,
      angle: 90,
      baseWidth: baseW,
      baseHeight: baseH,
    );

    expect(mapped.left, closeTo(original.left, 2));
    expect(mapped.top, closeTo(original.top, 2));
    expect(mapped.width, closeTo(original.width, 3));
    expect(mapped.height, closeTo(original.height, 3));
  });

  test('merge combina campos de múltiplas leituras por consenso', () {
    final linesPass1 = [
      (text: 'Portador', rect: const Rect.fromLTWH(50, 80, 80, 18)),
      (text: 'JOSE DA SILVA', rect: const Rect.fromLTWH(50, 100, 220, 18)),
      (text: 'Id. Funcional', rect: const Rect.fromLTWH(50, 200, 100, 18)),
      (text: '123456', rect: const Rect.fromLTWH(160, 200, 80, 18)),
    ];

    final linesPass2 = [
      (text: 'Portador', rect: const Rect.fromLTWH(55, 85, 80, 18)),
      (text: 'JOSE DA SILVA SANTOS', rect: const Rect.fromLTWH(55, 105, 260, 18)),
      (text: 'Id Funcional', rect: const Rect.fromLTWH(55, 205, 100, 18)),
      (text: '123456', rect: const Rect.fromLTWH(165, 205, 80, 18)),
    ];

    final scan1 = DocumentoOcrOrientacaoMerge.buildScan(
      angle: 0,
      rawLines: linesPass1,
      baseWidth: 1000,
      baseHeight: 800,
      scaleToOriginalX: 1,
      scaleToOriginalY: 1,
      forcaSigla: 'BMRS',
      tipoDocumento: 'funcional',
    );

    final scan2 = DocumentoOcrOrientacaoMerge.buildScan(
      angle: 0,
      rawLines: linesPass2,
      baseWidth: 1000,
      baseHeight: 800,
      scaleToOriginalX: 1,
      scaleToOriginalY: 1,
      forcaSigla: 'BMRS',
      tipoDocumento: 'funcional',
    );

    final merged = DocumentoOcrOrientacaoMerge.merge(
      [scan1, scan2],
      forcaSigla: 'BMRS',
      tipoDocumento: 'funcional',
    );

    expect(merged.fields.nome, 'JOSE DA SILVA SANTOS');
    expect(merged.fields.matricula, '123456');
    expect(
      merged.blocks.any((b) => b.category == OcrBlockCategory.nome),
      isTrue,
    );
  });

  test('mapRectFromBase é a inversa de mapRectToBase', () {
    const baseW = 1000;
    const baseH = 800;
    const rect = Rect.fromLTWH(120, 240, 180, 24);

    for (final angle in [90, 180, 270]) {
      final rotated = OcrOrientacaoMapper.mapRectFromBase(
        rect: rect,
        angle: angle,
        baseWidth: baseW,
        baseHeight: baseH,
      );
      final back = OcrOrientacaoMapper.mapRectToBase(
        rect: rotated,
        angle: angle,
        baseWidth: baseW,
        baseHeight: baseH,
      );

      expect(back.left, closeTo(rect.left, 1), reason: 'angle $angle');
      expect(back.top, closeTo(rect.top, 1), reason: 'angle $angle');
      expect(back.width, closeTo(rect.width, 1), reason: 'angle $angle');
      expect(back.height, closeTo(rect.height, 1), reason: 'angle $angle');
    }
  });

  test('face vertical: âncoras funcionam no espaço rotacionado e rects voltam à base', () {
    // Linhas como o OCR devolve na imagem já girada 90°: texto na horizontal.
    final rawLines = [
      (text: 'Portador', rect: const Rect.fromLTWH(50, 80, 90, 18)),
      (text: 'JOSE DA SILVA', rect: const Rect.fromLTWH(50, 100, 220, 18)),
      (text: 'Posto/Graduação', rect: const Rect.fromLTWH(50, 200, 130, 18)),
      (text: 'SARGENTO', rect: const Rect.fromLTWH(50, 220, 120, 18)),
    ];

    final scan = DocumentoOcrOrientacaoMerge.buildScan(
      angle: 90,
      rawLines: rawLines,
      baseWidth: 1000,
      baseHeight: 800,
      scaleToOriginalX: 1,
      scaleToOriginalY: 1,
      forcaSigla: 'BMRS',
      tipoDocumento: 'funcional',
    );

    expect(scan.extraction.fields.nome, 'JOSE DA SILVA');
    expect(scan.extraction.fields.cargo, 'SARGENTO');

    // Na imagem original a linha do nome é vertical, então o retângulo mapeado
    // de volta precisa ser mais alto que largo — é o que a redação vai usar.
    final nomeBlock = scan.extraction.blocks.firstWhere(
      (b) => b.text == 'JOSE DA SILVA',
    );
    expect(nomeBlock.rect.height, greaterThan(nomeBlock.rect.width));
    expect(nomeBlock.rect.right, lessThanOrEqualTo(1000));
    expect(nomeBlock.rect.bottom, lessThanOrEqualTo(800));
  });

  test('Google Vision: bloco vertical girado pela orientação vira legível por âncoras', () {
    const baseW = 1000;
    const baseH = 800;

    // Coordenadas como o Vision devolve: bloco lido de cima para baixo
    // (orientation 90) na face vertical da funcional.
    final visionRects = <({String text, Rect rect})>[
      (text: 'Portador', rect: const Rect.fromLTRB(300, 100, 320, 190)),
      (text: 'JOSE DA SILVA', rect: const Rect.fromLTRB(270, 100, 290, 320)),
    ];

    final emEspacoDeTexto = OcrOrientacaoMapper.mapLinesFromBase(
      lines: visionRects,
      angle: 90,
      baseWidth: baseW,
      baseHeight: baseH,
    );

    // Depois de girar, as linhas ficam horizontais e o rótulo acima do valor.
    for (final line in emEspacoDeTexto) {
      expect(line.rect.width, greaterThan(line.rect.height), reason: line.text);
    }

    final scan = DocumentoOcrOrientacaoMerge.buildScan(
      angle: 90,
      rawLines: emEspacoDeTexto,
      baseWidth: baseW,
      baseHeight: baseH,
      scaleToOriginalX: 1,
      scaleToOriginalY: 1,
      forcaSigla: 'BMRS',
      tipoDocumento: 'funcional',
    );

    expect(scan.extraction.fields.nome, 'JOSE DA SILVA');

    // E o retângulo volta para onde o texto realmente está na imagem original.
    final nomeBlock = scan.extraction.blocks.firstWhere(
      (b) => b.text == 'JOSE DA SILVA',
    );
    expect(nomeBlock.rect.left, closeTo(270, 2));
    expect(nomeBlock.rect.top, closeTo(100, 2));
  });

  group('documento aberto: as duas faces numa única foto', () {
    // Foto única com a metade vertical (Portador/nome, lido de cima para baixo)
    // e a metade horizontal (Id. Funcional) na mesma imagem.
    const baseW = 1000;
    const baseH = 800;

    final metadeHorizontal = <({String text, Rect rect})>[
      (text: 'Id. Funcional', rect: const Rect.fromLTWH(400, 500, 130, 20)),
      (text: '1234567', rect: const Rect.fromLTWH(545, 500, 80, 20)),
    ];

    final metadeVerticalNaBase = <({String text, Rect rect})>[
      (text: 'Portador', rect: const Rect.fromLTRB(300, 100, 320, 190)),
      (text: 'JOSE DA SILVA', rect: const Rect.fromLTRB(270, 100, 290, 320)),
    ];

    test('Tesseract combina a leitura de 0° e de 90° da mesma imagem', () {
      // 0°: só a metade horizontal é legível.
      final scan0 = DocumentoOcrOrientacaoMerge.buildScan(
        angle: 0,
        rawLines: metadeHorizontal,
        baseWidth: baseW,
        baseHeight: baseH,
        scaleToOriginalX: 1,
        scaleToOriginalY: 1,
        forcaSigla: 'BMRS',
        tipoDocumento: 'funcional',
      );

      // 90°: girando a foto, a metade vertical fica legível.
      final scan90 = DocumentoOcrOrientacaoMerge.buildScan(
        angle: 90,
        rawLines: OcrOrientacaoMapper.mapLinesFromBase(
          lines: metadeVerticalNaBase,
          angle: 90,
          baseWidth: baseW,
          baseHeight: baseH,
        ),
        baseWidth: baseW,
        baseHeight: baseH,
        scaleToOriginalX: 1,
        scaleToOriginalY: 1,
        forcaSigla: 'BMRS',
        tipoDocumento: 'funcional',
      );

      expect(scan0.extraction.fields.matricula, '1234567');
      expect(scan0.extraction.fields.nome, isNull);
      expect(scan90.extraction.fields.nome, 'JOSE DA SILVA');
      expect(scan90.extraction.fields.matricula, isNull);

      final merged = DocumentoOcrOrientacaoMerge.merge(
        [scan0, scan90],
        forcaSigla: 'BMRS',
        tipoDocumento: 'funcional',
      );

      expect(merged.fields.nome, 'JOSE DA SILVA');
      expect(merged.fields.matricula, '1234567');
    });

    test('Google Vision resolve numa só chamada, separando por orientação', () {
      // O Vision devolve tudo junto, com a orientação de cada bloco.
      final porOrientacao = <int, List<({String text, Rect rect})>>{
        0: metadeHorizontal,
        90: metadeVerticalNaBase,
      };

      final scans = [
        for (final entry in porOrientacao.entries)
          DocumentoOcrOrientacaoMerge.buildScan(
            angle: entry.key,
            rawLines: OcrOrientacaoMapper.mapLinesFromBase(
              lines: entry.value,
              angle: entry.key,
              baseWidth: baseW,
              baseHeight: baseH,
            ),
            baseWidth: baseW,
            baseHeight: baseH,
            scaleToOriginalX: 1,
            scaleToOriginalY: 1,
            forcaSigla: 'BMRS',
            tipoDocumento: 'funcional',
          ),
      ];

      final merged = DocumentoOcrOrientacaoMerge.merge(
        scans,
        forcaSigla: 'BMRS',
        tipoDocumento: 'funcional',
      );

      expect(merged.fields.nome, 'JOSE DA SILVA');
      expect(merged.fields.matricula, '1234567');

      // As tarjas voltam para a posição real de cada metade da foto.
      final nomeBlock = merged.blocks.firstWhere((b) => b.text == 'JOSE DA SILVA');
      expect(nomeBlock.rect.left, closeTo(270, 2));
      expect(nomeBlock.rect.top, closeTo(100, 2));

      final matriculaBlock = merged.blocks.firstWhere((b) => b.text == '1234567');
      expect(matriculaBlock.rect.left, closeTo(545, 2));
      expect(matriculaBlock.rect.top, closeTo(500, 2));
    });
  });

  test('faces distintas se completam: nome/cargo numa, matrícula na outra', () {
    const faceVertical = ExtractedVerificationFields(
      nome: 'JOSE DA SILVA',
      cargo: 'SARGENTO',
    );
    const faceHorizontal = ExtractedVerificationFields(
      matricula: '1234567',
      forca: 'BMRS',
    );

    final merged = DocumentoFieldsMerge.merge(
      [faceVertical, faceHorizontal],
      forcaSigla: 'BMRS',
    );

    expect(merged.nome, 'JOSE DA SILVA');
    expect(merged.cargo, 'SARGENTO');
    expect(merged.matricula, '1234567');
    expect(merged.forca, 'BMRS');
  });

  test('nome não é preenchido com posto e cargo não é preenchido com nome', () {
    expect(
      DocumentoFieldsMerge.pickNome(['SARGENTO']),
      isNull,
      reason: 'posto não pode virar nome',
    );
    expect(
      DocumentoFieldsMerge.pickCargo(['JOSE DA SILVA SANTOS']),
      isNull,
      reason: 'nome de pessoa não pode virar cargo',
    );
    expect(
      DocumentoFieldsMerge.pickCargo(['JOSE DA SILVA', 'CABO']),
      'CABO',
    );
  });
}
