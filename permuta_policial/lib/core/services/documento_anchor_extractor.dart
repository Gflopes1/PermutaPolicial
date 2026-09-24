import 'dart:ui';

import '../config/documento_campo_config.dart';
import '../config/matricula_regex_config.dart';
import 'documento_field_semantics.dart';
import 'verificacao_ocr_redaction.dart';

/// Extração de campos por âncoras (rótulos) + posição espacial.
///
/// Plano B (não implementado): recorte manual de cada campo relevante pelo
/// usuário (ex.: [image_cropper]) e OCR apenas no recorte — ver
/// [DocumentoCampoConfigRegistry].
class AnchorExtractionResult {
  final List<OcrTextBlock> blocks;
  final ExtractedVerificationFields fields;
  final DocumentoTipoConfig? matchedConfig;

  const AnchorExtractionResult({
    required this.blocks,
    required this.fields,
    this.matchedConfig,
  });
}

class DocumentoAnchorExtractor {
  DocumentoAnchorExtractor._();

  static final _cpfValidation = RegExp(r'\d{3}\.\d{3}\.\d{3}-\d{2}');
  static final _moneyValidation = RegExp(r'R\$\s?[\d.,]+', caseSensitive: false);
  static final _bankValidation = RegExp(
    r'(ag[eê]ncia|conta|banco|pix)\s*[:\-]?\s*[\d./\-Xx]+',
    caseSensitive: false,
  );
  static final _addressValidation = RegExp(
    r'\b(rua|avenida|av\.|travessa|alameda|rodovia|cep)\b',
    caseSensitive: false,
  );

  static AnchorExtractionResult extract({
    required List<({String text, Rect rect})> lines,
    String? forcaSigla,
    String? tipoDocumento,
    String? nomeCadastrado,
    String? matriculaCadastrada,
  }) {
    final rawBlocks = lines
        .where((line) => line.text.trim().isNotEmpty)
        .map(
          (line) => OcrTextBlock(
            text: line.text.trim(),
            rect: line.rect,
            category: OcrBlockCategory.other,
          ),
        )
        .toList();

    final config = DocumentoCampoConfigRegistry.resolve(
      lines: lines,
      forcaSigla: forcaSigla,
      tipoDocumento: tipoDocumento,
    );

    final categoryByIndex = List<OcrBlockCategory>.filled(
      rawBlocks.length,
      OcrBlockCategory.other,
    );
    final usedValueIndices = <int>{};

    String? nome;
    String? matricula;
    String? forca;
    String? cargo;

    if (config != null) {
      final sortedCampos = [...config.campos]..sort((a, b) {
          int priority(CampoConfig c) => switch (c.extrairComo) {
                CampoVerificacao.nome => 0,
                CampoVerificacao.matricula => 1,
                CampoVerificacao.forca => 2,
                CampoVerificacao.cargo => 3,
                null => 10,
              };
          return priority(a).compareTo(priority(b));
        });

      for (final campo in sortedCampos) {
        for (var i = 0; i < rawBlocks.length; i++) {
          final labelBlock = rawBlocks[i];
          if (!matchesLabel(labelBlock.text, campo.rotulos)) continue;

          if (campo.finalidade == CampoFinalidade.identificacao &&
              campo.extrairComo == CampoVerificacao.forca) {
            forca ??= _forcaFromHeader(labelBlock.text, config.forcaSigla);
            continue;
          }

          final inlineValue = _inlineValue(labelBlock.text, campo.rotulos);
          if (inlineValue != null) {
            _applyValue(
              campo: campo,
              valueText: inlineValue,
              valueIndex: i,
              categoryByIndex: categoryByIndex,
              usedValueIndices: usedValueIndices,
              nome: () => nome,
              setNome: (v) => nome = v,
              matricula: () => matricula,
              setMatricula: (v) => matricula = v,
              forca: () => forca,
              setForca: (v) => forca = v,
              cargo: () => cargo,
              setCargo: (v) => cargo = v,
              forcaSigla: forcaSigla ?? config.forcaSigla,
            );
            continue;
          }

          final valueBlocks = _findValueBlocks(
            labelBlock: labelBlock,
            labelIndex: i,
            allBlocks: rawBlocks,
            campo: campo,
            usedValueIndices: usedValueIndices,
          );

          for (final entry in valueBlocks) {
            _applyValue(
              campo: campo,
              valueText: entry.text,
              valueIndex: entry.index,
              categoryByIndex: categoryByIndex,
              usedValueIndices: usedValueIndices,
              nome: () => nome,
              setNome: (v) => nome = v,
              matricula: () => matricula,
              setMatricula: (v) => matricula = v,
              forca: () => forca,
              setForca: (v) => forca = v,
              cargo: () => cargo,
              setCargo: (v) => cargo = v,
              forcaSigla: forcaSigla ?? config.forcaSigla,
            );
          }
        }
      }

      if (forca == null && config.forcaSigla.isNotEmpty) {
        for (final header in config.cabecalhosIdentificacao) {
          for (final block in rawBlocks) {
            if (matchesLabel(block.text, [header])) {
              forca = _forcaFromHeader(block.text, config.forcaSigla);
              break;
            }
          }
          if (forca != null) break;
        }
      }
    }

    for (var i = 0; i < rawBlocks.length; i++) {
      if (usedValueIndices.contains(i)) continue;
      if (categoryByIndex[i] != OcrBlockCategory.other) continue;
      if (_isBlockLevelSensitive(rawBlocks[i].text)) {
        categoryByIndex[i] = OcrBlockCategory.sensitive;
      }
    }

    _applyProfileHints(
      rawBlocks: rawBlocks,
      categoryByIndex: categoryByIndex,
      nomeCadastrado: nomeCadastrado,
      matriculaCadastrada: matriculaCadastrada,
      setNome: (v) => nome = v,
      setMatricula: (v) => matricula = v,
    );

    final blocks = [
      for (var i = 0; i < rawBlocks.length; i++)
        OcrTextBlock(
          text: rawBlocks[i].text,
          rect: rawBlocks[i].rect,
          category: categoryByIndex[i],
        ),
    ];

    return AnchorExtractionResult(
      blocks: blocks,
      fields: ExtractedVerificationFields(
        nome: nome?.trim(),
        matricula: matricula?.trim(),
        forca: forca?.trim(),
        cargo: cargo?.trim(),
      ),
      matchedConfig: config,
    );
  }

  static bool matchesLabel(String text, List<String> rotulos) {
    final normalized = _normalizeForLabelMatch(text);
    for (final rotulo in rotulos) {
      final target = _normalizeForLabelMatch(rotulo);
      if (normalized == target) return true;
      if (normalized.contains(target) && target.length >= 3) return true;
      if (_levenshteinRatio(normalized, target) >= 0.82 && target.length >= 4) {
        return true;
      }
    }
    return false;
  }

  static String _normalizeForLabelMatch(String value) {
    return value
        .toLowerCase()
        .replaceAll('ld.', 'id.')
        .replaceAll('ld ', 'id ')
        .replaceAll(RegExp(r'[.\-:/]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static double _levenshteinRatio(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1;
    if (a.isEmpty || b.isEmpty) return 0;
    final distance = _levenshteinDistance(a, b);
    return 1 - distance / (a.length > b.length ? a.length : b.length);
  }

  static int _levenshteinDistance(String a, String b) {
    final m = a.length;
    final n = b.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      dp[0][j] = j;
    }
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return dp[m][n];
  }

  static String? _inlineValue(String blockText, List<String> rotulos) {
    for (final rotulo in rotulos) {
      final pattern = RegExp(
        '${RegExp.escape(rotulo)}\\s*[:-]?\\s*(.+)',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(blockText);
      if (match != null) {
        final value = match.group(1)?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }
    return null;
  }

  static List<({int index, String text})> _findValueBlocks({
    required OcrTextBlock labelBlock,
    required int labelIndex,
    required List<OcrTextBlock> allBlocks,
    required CampoConfig campo,
    required Set<int> usedValueIndices,
  }) {
    // Layouts variam entre faces e emissões do mesmo documento, então um campo
    // de verificação aceita o valor na outra posição quando a principal falha.
    final permiteFallback = campo.finalidade == CampoFinalidade.verificacao;

    switch (campo.posicao) {
      case ValorPosicao.direita:
        final block = _nearestRight(labelBlock, labelIndex, allBlocks, usedValueIndices) ??
            (permiteFallback
                ? _nearestBelow(labelBlock, labelIndex, allBlocks, usedValueIndices)
                : null);
        return block == null ? [] : [block];
      case ValorPosicao.abaixo:
        final block = _nearestBelow(labelBlock, labelIndex, allBlocks, usedValueIndices) ??
            (permiteFallback
                ? _nearestRight(labelBlock, labelIndex, allBlocks, usedValueIndices)
                : null);
        return block == null ? [] : [block];
      case ValorPosicao.abaixoMultiplo:
        return _nearestBelowMultiple(
          labelBlock,
          labelIndex,
          allBlocks,
          usedValueIndices,
          campo.linhasAbaixo,
        );
    }
  }

  static ({int index, String text})? _nearestRight(
    OcrTextBlock labelBlock,
    int labelIndex,
    List<OcrTextBlock> allBlocks,
    Set<int> usedValueIndices,
  ) {
    final labelCenterY = labelBlock.rect.center.dy;
    final labelHeight = labelBlock.rect.height;
    ({int index, String text})? best;
    var bestDistance = double.infinity;

    for (var i = 0; i < allBlocks.length; i++) {
      if (i == labelIndex || usedValueIndices.contains(i)) continue;
      final candidate = allBlocks[i];
      if (matchesAnyKnownLabel(candidate.text)) continue;

      final sameLine = (candidate.rect.center.dy - labelCenterY).abs() <= labelHeight * 0.75;
      if (!sameLine) continue;

      final horizontalGap = candidate.rect.left - labelBlock.rect.right;
      if (horizontalGap < -labelHeight * 0.3) continue;

      final distance = horizontalGap.abs() + (candidate.rect.center.dy - labelCenterY).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = (index: i, text: candidate.text);
      }
    }

    return best;
  }

  static ({int index, String text})? _nearestBelow(
    OcrTextBlock labelBlock,
    int labelIndex,
    List<OcrTextBlock> allBlocks,
    Set<int> usedValueIndices,
  ) {
    final labelCenterX = labelBlock.rect.center.dx;
    final labelWidth = labelBlock.rect.width;
    ({int index, String text})? best;
    var bestDistance = double.infinity;

    for (var i = 0; i < allBlocks.length; i++) {
      if (i == labelIndex || usedValueIndices.contains(i)) continue;
      final candidate = allBlocks[i];
      if (matchesAnyKnownLabel(candidate.text)) continue;

      final verticalGap = candidate.rect.top - labelBlock.rect.bottom;
      if (verticalGap < -labelBlock.rect.height * 0.2) continue;
      if (verticalGap > labelBlock.rect.height * 3) continue;

      final horizontalDelta = (candidate.rect.center.dx - labelCenterX).abs();
      if (horizontalDelta > labelWidth * 2.5) continue;

      final distance = verticalGap + horizontalDelta * 0.35;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = (index: i, text: candidate.text);
      }
    }

    return best;
  }

  static List<({int index, String text})> _nearestBelowMultiple(
    OcrTextBlock labelBlock,
    int labelIndex,
    List<OcrTextBlock> allBlocks,
    Set<int> usedValueIndices,
    int count,
  ) {
    final labelCenterX = labelBlock.rect.center.dx;
    final candidates = <({int index, String text, double score})>[];

    for (var i = 0; i < allBlocks.length; i++) {
      if (i == labelIndex || usedValueIndices.contains(i)) continue;
      final candidate = allBlocks[i];
      if (matchesAnyKnownLabel(candidate.text)) continue;

      final verticalGap = candidate.rect.top - labelBlock.rect.bottom;
      if (verticalGap < -labelBlock.rect.height * 0.2) continue;
      if (verticalGap > labelBlock.rect.height * 5) continue;

      final horizontalDelta = (candidate.rect.center.dx - labelCenterX).abs();
      if (horizontalDelta > labelBlock.rect.width * 3) continue;

      candidates.add((
        index: i,
        text: candidate.text,
        score: verticalGap + horizontalDelta * 0.35,
      ));
    }

    candidates.sort((a, b) => a.score.compareTo(b.score));
    return candidates
        .take(count)
        .map((c) => (index: c.index, text: c.text))
        .toList();
  }

  static bool matchesAnyKnownLabel(String text) {
    for (final config in DocumentoCampoConfigRegistry.configs) {
      for (final campo in config.campos) {
        if (matchesLabel(text, campo.rotulos)) return true;
      }
    }
    return false;
  }

  static void _applyValue({
    required CampoConfig campo,
    required String valueText,
    required int valueIndex,
    required List<OcrBlockCategory> categoryByIndex,
    required Set<int> usedValueIndices,
    required String? Function() nome,
    required void Function(String?) setNome,
    required String? Function() matricula,
    required void Function(String?) setMatricula,
    required String? Function() forca,
    required void Function(String?) setForca,
    required String? Function() cargo,
    required void Function(String?) setCargo,
    required String? forcaSigla,
  }) {
    final cleaned = valueText.trim();
    if (cleaned.isEmpty) return;

    if (campo.id == 'cpf') {
      categoryByIndex[valueIndex] = OcrBlockCategory.sensitive;
      usedValueIndices.add(valueIndex);
      return;
    }

    if (campo.validacaoPattern != null) {
      final validation = RegExp(campo.validacaoPattern!);
      if (!validation.hasMatch(cleaned)) return;
    }

    if (!_isValidExtractedValue(cleaned, campo)) return;

    usedValueIndices.add(valueIndex);

    switch (campo.finalidade) {
      case CampoFinalidade.sensivel:
        categoryByIndex[valueIndex] = OcrBlockCategory.sensitive;
        break;
      case CampoFinalidade.verificacao:
      case CampoFinalidade.identificacao:
        final category = _categoryForCampo(campo.extrairComo);
        if (category != null) {
          categoryByIndex[valueIndex] = category;
        }
        switch (campo.extrairComo) {
          case CampoVerificacao.nome:
            if (nome()?.trim().isNotEmpty != true) setNome(cleaned);
          case CampoVerificacao.matricula:
            if (MatriculaRegexConfig.isValid(cleaned, forcaSigla) ||
                campo.validacaoPattern == null) {
              if (matricula()?.trim().isNotEmpty != true) setMatricula(cleaned);
            }
          case CampoVerificacao.cargo:
            if (cargo()?.trim().isNotEmpty != true) setCargo(cleaned);
          case CampoVerificacao.forca:
            if (forca()?.trim().isNotEmpty != true) setForca(cleaned);
          case null:
            break;
        }
        break;
    }
  }

  static bool _isValidExtractedValue(String value, CampoConfig campo) {
    return switch (campo.extrairComo) {
      CampoVerificacao.nome => DocumentoFieldSemantics.isValidForField(
          value: value,
          isNome: true,
          isCargo: false,
        ),
      CampoVerificacao.cargo => DocumentoFieldSemantics.isValidForField(
          value: value,
          isNome: false,
          isCargo: true,
        ),
      _ => true,
    };
  }

  static OcrBlockCategory? _categoryForCampo(CampoVerificacao? campo) {
    return switch (campo) {
      CampoVerificacao.nome => OcrBlockCategory.nome,
      CampoVerificacao.matricula => OcrBlockCategory.matricula,
      CampoVerificacao.cargo => OcrBlockCategory.cargo,
      CampoVerificacao.forca => OcrBlockCategory.forca,
      null => null,
    };
  }

  static String _forcaFromHeader(String text, String forcaSigla) {
    if (forcaSigla.isNotEmpty) return forcaSigla;
    final upper = text.toUpperCase();
    if (upper.contains('BRIGADA MILITAR')) return 'BMRS';
    if (upper.contains('PMESP') || upper.contains('POLICIA MILITAR')) return 'PMESP';
    if (upper.contains('PMERJ')) return 'PMERJ';
    if (upper.contains('PRF')) return 'PRF';
    if (upper.contains('PF')) return 'PF';
    return text.trim();
  }

  static bool _isBlockLevelSensitive(String text) {
    return _cpfValidation.hasMatch(text) ||
        _moneyValidation.hasMatch(text) ||
        _bankValidation.hasMatch(text) ||
        _addressValidation.hasMatch(text);
  }

  static void _applyProfileHints({
    required List<OcrTextBlock> rawBlocks,
    required List<OcrBlockCategory> categoryByIndex,
    String? nomeCadastrado,
    String? matriculaCadastrada,
    required void Function(String?) setNome,
    required void Function(String?) setMatricula,
  }) {
    if (nomeCadastrado != null && nomeCadastrado.trim().isNotEmpty) {
      final normalizedCadastro = _normalizeName(nomeCadastrado);
      for (var i = 0; i < rawBlocks.length; i++) {
        if (categoryByIndex[i] == OcrBlockCategory.sensitive) continue;
        if (_namesSimilar(normalizedCadastro, _normalizeName(rawBlocks[i].text))) {
          categoryByIndex[i] = OcrBlockCategory.nome;
          setNome(rawBlocks[i].text);
          break;
        }
      }
    }

    if (matriculaCadastrada != null && matriculaCadastrada.trim().isNotEmpty) {
      final target = matriculaCadastrada.replaceAll(RegExp(r'[.\-/]'), '');
      for (var i = 0; i < rawBlocks.length; i++) {
        if (categoryByIndex[i] == OcrBlockCategory.sensitive) continue;
        final digits = rawBlocks[i].text.replaceAll(RegExp(r'[.\-/]'), '');
        if (digits.contains(target) || target.contains(digits)) {
          categoryByIndex[i] = OcrBlockCategory.matricula;
          setMatricula(rawBlocks[i].text);
          break;
        }
      }
    }
  }

  static String _normalizeName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zà-ÿ\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _namesSimilar(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    return a.contains(b) || b.contains(a);
  }
}
