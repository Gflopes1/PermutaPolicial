import 'dart:ui';

import '../config/matricula_regex_config.dart';
import 'documento_anchor_extractor.dart';
import 'documento_field_semantics.dart';
import 'documento_ocr_pipeline.dart';
import 'verificacao_ocr_redaction.dart';

/// Resultado de OCR em uma orientação específica.
class OrientedOcrScan {
  final int angle;
  final List<({String text, Rect rect})> lines;
  final List<({String text, Rect rect})> words;
  final AnchorExtractionResult extraction;
  final int confidenceScore;

  const OrientedOcrScan({
    required this.angle,
    required this.lines,
    this.words = const [],
    required this.extraction,
    required this.confidenceScore,
  });
}

/// Mapeia coordenadas de retângulos da imagem rotacionada de volta à base (0°).
class OcrOrientacaoMapper {
  OcrOrientacaoMapper._();

  /// Converte [rect] da imagem rotacionada em [angle]° CW para coords da base 0°.
  static Rect mapRectToBase({
    required Rect rect,
    required int angle,
    required int baseWidth,
    required int baseHeight,
  }) {
    if (angle == 0) return rect;

    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ].map((p) => _mapPointToBase(p, angle, baseWidth, baseHeight));

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

    return Rect.fromLTRB(
      left.clamp(0, baseWidth.toDouble()),
      top.clamp(0, baseHeight.toDouble()),
      right.clamp(0, baseWidth.toDouble()),
      bottom.clamp(0, baseHeight.toDouble()),
    );
  }

  /// Inversa de rotação horária (como [img.copyRotate] com angle positivo).
  static Offset _mapPointToBase(Offset p, int angle, int baseW, int baseH) {
    return switch (angle) {
      90 => Offset(baseW - p.dy, p.dx),
      180 => Offset(baseW - p.dx, baseH - p.dy),
      270 => Offset(p.dy, baseH - p.dx),
      _ => p,
    };
  }

  /// Converte [rect] das coords da base (0°) para a imagem rotacionada em [angle]° CW.
  ///
  /// Usado quando o OCR devolve coordenadas na base (ex.: Google Vision) mas o
  /// texto de um bloco está girado — a extração por âncoras precisa rodar no
  /// espaço em que aquele texto fica na horizontal.
  static Rect mapRectFromBase({
    required Rect rect,
    required int angle,
    required int baseWidth,
    required int baseHeight,
  }) {
    if (angle == 0) return rect;

    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ].map((p) => _mapPointFromBase(p, angle, baseWidth, baseHeight));

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

    final rotatedWidth = angle == 180 ? baseWidth : baseHeight;
    final rotatedHeight = angle == 180 ? baseHeight : baseWidth;

    return Rect.fromLTRB(
      left.clamp(0, rotatedWidth.toDouble()),
      top.clamp(0, rotatedHeight.toDouble()),
      right.clamp(0, rotatedWidth.toDouble()),
      bottom.clamp(0, rotatedHeight.toDouble()),
    );
  }

  static Offset _mapPointFromBase(Offset p, int angle, int baseW, int baseH) {
    return switch (angle) {
      90 => Offset(p.dy, baseW - p.dx),
      180 => Offset(baseW - p.dx, baseH - p.dy),
      270 => Offset(baseH - p.dy, p.dx),
      _ => p,
    };
  }

  static List<({String text, Rect rect})> mapLinesFromBase({
    required List<({String text, Rect rect})> lines,
    required int angle,
    required int baseWidth,
    required int baseHeight,
  }) {
    return lines
        .map(
          (line) => (
            text: line.text,
            rect: mapRectFromBase(
              rect: line.rect,
              angle: angle,
              baseWidth: baseWidth,
              baseHeight: baseHeight,
            ),
          ),
        )
        .toList();
  }

  static List<({String text, Rect rect})> mapLinesToBase({
    required List<({String text, Rect rect})> lines,
    required int angle,
    required int baseWidth,
    required int baseHeight,
  }) {
    return lines
        .map(
          (line) => (
            text: line.text,
            rect: mapRectToBase(
              rect: line.rect,
              angle: angle,
              baseWidth: baseWidth,
              baseHeight: baseHeight,
            ),
          ),
        )
        .toList();
  }
}

/// Combina resultados de OCR em múltiplas orientações, priorizando dados mais confiáveis.
class DocumentoOcrOrientacaoMerge {
  DocumentoOcrOrientacaoMerge._();

  static OrientedOcrScan buildScan({
    required int angle,
    required List<({String text, Rect rect})> rawLines,
    List<({String text, Rect rect})> rawWords = const [],
    required int baseWidth,
    required int baseHeight,
    required double scaleToOriginalX,
    required double scaleToOriginalY,
    String? forcaSigla,
    String? tipoDocumento,
    String? nomeCadastrado,
    String? matriculaCadastrada,
  }) {
    // A extração roda nas coordenadas da imagem rotacionada, onde o texto está
    // na horizontal. Se rodasse no espaço da base, um bloco vertical teria as
    // relações rótulo→valor ("à direita", "abaixo") trocadas.
    final extraction = DocumentoOcrPipeline.extractFromLines(
      rawLines,
      forcaSigla: forcaSigla,
      tipoDocumento: tipoDocumento,
      nomeCadastrado: nomeCadastrado,
      matriculaCadastrada: matriculaCadastrada,
    );

    Rect toOriginal(Rect rect) {
      final base = OcrOrientacaoMapper.mapRectToBase(
        rect: rect,
        angle: angle,
        baseWidth: baseWidth,
        baseHeight: baseHeight,
      );
      return Rect.fromLTRB(
        base.left * scaleToOriginalX,
        base.top * scaleToOriginalY,
        base.right * scaleToOriginalX,
        base.bottom * scaleToOriginalY,
      );
    }

    final lines = rawLines
        .map((line) => (text: line.text, rect: toOriginal(line.rect)))
        .toList();
    final words = rawWords
        .map((word) => (text: word.text, rect: toOriginal(word.rect)))
        .toList();

    final mappedExtraction = AnchorExtractionResult(
      blocks: [
        for (final block in extraction.blocks)
          OcrTextBlock(
            text: block.text,
            rect: toOriginal(block.rect),
            category: block.category,
          ),
      ],
      fields: extraction.fields,
      matchedConfig: extraction.matchedConfig,
    );

    final score = _scoreExtraction(
      extraction,
      lineCount: lines.length,
      forcaSigla: forcaSigla,
      nomeCadastrado: nomeCadastrado,
      matriculaCadastrada: matriculaCadastrada,
    );

    return OrientedOcrScan(
      angle: angle,
      lines: lines,
      words: words,
      extraction: mappedExtraction,
      confidenceScore: score,
    );
  }

  static ({List<OcrTextBlock> blocks, ExtractedVerificationFields fields}) merge(
    List<OrientedOcrScan> scans, {
    String? forcaSigla,
    String? tipoDocumento,
    String? nomeCadastrado,
    String? matriculaCadastrada,
  }) {
    if (scans.isEmpty) {
      return (
        blocks: const <OcrTextBlock>[],
        fields: const ExtractedVerificationFields(),
      );
    }

    // Cada scan já foi extraído no seu próprio espaço de leitura, então a fusão
    // trabalha só sobre os resultados — juntar linhas de orientações diferentes
    // num único espaço produziria âncoras inválidas.
    final fields = _mergeFields(
      scans,
      const ExtractedVerificationFields(),
      forcaSigla: forcaSigla,
      nomeCadastrado: nomeCadastrado,
      matriculaCadastrada: matriculaCadastrada,
    );

    final blocks = _mergeBlocks(
      scans.map((s) => s.extraction.blocks).toList(),
      const <OcrTextBlock>[],
    );

    return (blocks: blocks, fields: fields);
  }

  static int _scoreExtraction(
    AnchorExtractionResult extraction, {
    required int lineCount,
    String? forcaSigla,
    String? nomeCadastrado,
    String? matriculaCadastrada,
  }) {
    var score = 0;
    final fields = extraction.fields;

    if (extraction.matchedConfig != null) score += 15;
    if (lineCount >= 8) score += 3;
    if (lineCount >= 15) score += 3;

    if (fields.nome != null && fields.nome!.trim().isNotEmpty) {
      score += 8;
      if (_namesSimilar(nomeCadastrado, fields.nome)) score += 12;
    }
    if (fields.matricula != null && fields.matricula!.trim().isNotEmpty) {
      score += 10;
      if (MatriculaRegexConfig.isValid(fields.matricula, forcaSigla)) score += 8;
      if (_matriculaSimilar(matriculaCadastrada, fields.matricula)) score += 12;
    }
    if (fields.cargo != null && fields.cargo!.trim().isNotEmpty) score += 6;
    if (fields.forca != null && fields.forca!.trim().isNotEmpty) score += 5;

    score += extraction.blocks
            .where((b) => b.category == OcrBlockCategory.sensitive)
            .length *
        2;

    return score;
  }

  static ExtractedVerificationFields _mergeFields(
    List<OrientedOcrScan> scans,
    ExtractedVerificationFields mergedFallback, {
    String? forcaSigla,
    String? nomeCadastrado,
    String? matriculaCadastrada,
  }) {
    final rankedScans = [...scans]..sort(
        (a, b) => b.confidenceScore.compareTo(a.confidenceScore),
      );

    return ExtractedVerificationFields(
      nome: _pickBestNome(
        rankedScans,
        mergedFallback.nome,
        profileHint: nomeCadastrado,
      ),
      matricula: _pickBestMatriculaFromScans(
        rankedScans,
        mergedFallback.matricula,
        forcaSigla: forcaSigla,
        profileHint: matriculaCadastrada,
      ),
      cargo: _pickBestCargo(rankedScans, mergedFallback.cargo),
      forca: _pickFieldByConfidence(rankedScans, (f) => f.forca) ??
          mergedFallback.forca,
    );
  }

  static String? _pickFieldByConfidence(
    List<OrientedOcrScan> rankedScans,
    String? Function(ExtractedVerificationFields f) getter,
  ) {
    for (final scan in rankedScans) {
      final value = getter(scan.extraction.fields)?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String? _pickBestCargo(
    List<OrientedOcrScan> rankedScans,
    String? fallback,
  ) {
    final candidates = [
      ...rankedScans.map((s) => s.extraction.fields.cargo),
      fallback,
    ].whereType<String>().map((v) => v.trim()).where((v) => v.isNotEmpty).toList();

    if (candidates.isEmpty) return null;

    for (final value in candidates) {
      if (DocumentoFieldSemantics.looksLikeRank(value)) return value;
    }
    for (final value in candidates) {
      if (!DocumentoFieldSemantics.looksLikePersonName(value)) return value;
    }
    return null;
  }

  static String? _pickBestNome(
    List<OrientedOcrScan> rankedScans,
    String? fallback, {
    String? profileHint,
  }) {
    final candidates = [
      ...rankedScans.map((s) => s.extraction.fields.nome),
      fallback,
    ]
        .whereType<String>()
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .where((v) => !DocumentoFieldSemantics.looksLikeRank(v))
        .toList();

    if (candidates.isEmpty) return null;

    if (profileHint != null && profileHint.trim().isNotEmpty) {
      for (final value in candidates) {
        if (_namesSimilar(profileHint, value)) return value;
      }
    }

    // Entre nomes similares, preferir o mais completo (ex.: com sobrenome extra).
    for (var i = 0; i < candidates.length; i++) {
      for (var j = i + 1; j < candidates.length; j++) {
        final a = _normalizeName(candidates[i]);
        final b = _normalizeName(candidates[j]);
        if (a.contains(b) || b.contains(a)) {
          return candidates[i].length >= candidates[j].length
              ? candidates[i]
              : candidates[j];
        }
      }
    }

    candidates.sort((a, b) => b.length.compareTo(a.length));
    return candidates.first;
  }

  static String? _pickBestMatriculaFromScans(
    List<OrientedOcrScan> rankedScans,
    String? fallback, {
    String? forcaSigla,
    String? profileHint,
  }) {
    final fromScans = _pickFieldByConfidence(
      rankedScans,
      (f) => f.matricula,
    );
    return _pickBestMatricula(
      [fromScans, fallback],
      forcaSigla: forcaSigla,
      profileHint: profileHint,
    );
  }

  static String? _pickBestValue(
    List<String?> values, {
    String? profileHint,
    bool preferLongest = false,
  }) {
    final cleaned = values
        .whereType<String>()
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return null;

    if (profileHint != null && profileHint.trim().isNotEmpty) {
      final hint = _normalizeName(profileHint);
      for (final value in cleaned) {
        if (_namesSimilar(hint, _normalizeName(value))) return value;
      }
    }

    final counts = <String, int>{};
    for (final value in cleaned) {
      counts[value] = (counts[value] ?? 0) + 1;
    }

    cleaned.sort((a, b) {
      final countCmp = (counts[b] ?? 0).compareTo(counts[a] ?? 0);
      if (countCmp != 0) return countCmp;
      if (preferLongest) return b.length.compareTo(a.length);
      return a.compareTo(b);
    });

    return cleaned.first;
  }

  static String? _pickBestMatricula(
    List<String?> values, {
    String? forcaSigla,
    String? profileHint,
  }) {
    final cleaned = values
        .whereType<String>()
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return null;

    if (profileHint != null && profileHint.trim().isNotEmpty) {
      for (final value in cleaned) {
        if (_matriculaSimilar(profileHint, value)) return value;
      }
    }

    final valid = cleaned
        .where((v) => MatriculaRegexConfig.isValid(v, forcaSigla))
        .toList();
    if (valid.isNotEmpty) {
      return _pickBestValue(valid);
    }

    return _pickBestValue(cleaned);
  }

  static List<OcrTextBlock> _mergeBlocks(
    List<List<OcrTextBlock>> perScanBlocks,
    List<OcrTextBlock> mergedFallback,
  ) {
    final all = [
      ...perScanBlocks.expand((b) => b),
      ...mergedFallback,
    ];

    final result = <OcrTextBlock>[];
    for (final block in all) {
      final existingIndex = result.indexWhere(
        (existing) =>
            existing.category == block.category &&
            existing.text.trim().toLowerCase() == block.text.trim().toLowerCase() &&
            _rectsOverlap(existing.rect, block.rect),
      );

      if (existingIndex < 0) {
        result.add(block);
        continue;
      }

      // Entre leituras de orientações diferentes, preferir o retângulo menor.
      final existing = result[existingIndex];
      final existingArea = existing.rect.width * existing.rect.height;
      final blockArea = block.rect.width * block.rect.height;
      if (blockArea < existingArea) {
        result[existingIndex] = block;
      }
    }

    return result;
  }

  static bool _rectsOverlap(Rect a, Rect b, {double threshold = 0.25}) {
    final intersection = Rect.fromLTRB(
      a.left > b.left ? a.left : b.left,
      a.top > b.top ? a.top : b.top,
      a.right < b.right ? a.right : b.right,
      a.bottom < b.bottom ? a.bottom : b.bottom,
    );
    if (intersection.width <= 0 || intersection.height <= 0) return false;

    final intersectionArea = intersection.width * intersection.height;
    final minArea = [
      a.width * a.height,
      b.width * b.height,
    ].reduce((x, y) => x < y ? x : y);

    return intersectionArea / minArea >= threshold;
  }

  static bool _namesSimilar(String? a, String? b) {
    if (a == null || b == null) return false;
    final na = _normalizeName(a);
    final nb = _normalizeName(b);
    if (na.isEmpty || nb.isEmpty) return false;
    return na == nb || na.contains(nb) || nb.contains(na);
  }

  static bool _matriculaSimilar(String? a, String? b) {
    if (a == null || b == null) return false;
    final da = a.replaceAll(RegExp(r'[.\-/]'), '');
    final db = b.replaceAll(RegExp(r'[.\-/]'), '');
    if (da.isEmpty || db.isEmpty) return false;
    return da == db || da.contains(db) || db.contains(da);
  }

  static String _normalizeName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zà-ÿ\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

}
