import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:image/image.dart' as img;

import '../api/repositories/verificacao_ocr_repository.dart';
import 'documento_auto_crop.dart';
import 'documento_image_loader.dart';
import 'documento_image_preprocess.dart';
import 'documento_ocr_orientacao.dart';
import 'documento_ocr_pipeline.dart';
import 'documento_ocr_types.dart';
import 'documento_orientation_detector.dart';
import '../utils/web_script_loader.dart';
import 'documento_preprocess_debug.dart';
import 'documento_quality_exception.dart';
import 'documento_quality_gate.dart';
import 'verificacao_ocr_redaction.dart';

/// Orquestra Google Vision (servidor) para OCR de documentos na web.
class DocumentoOcrCoordinator {
  DocumentoOcrCoordinator._();

  static Future<void> _yieldToUi() async {
    await Future<void>.delayed(Duration.zero);
    await SchedulerBinding.instance.endOfFrame;
  }

  static Future<DocumentoOcrResult> process({
    required Uint8List imageBytes,
    required VerificacaoOcrRepository visionRepository,
    String? forcaSigla,
    String? tipoDocumento,
    String? nomeCadastrado,
    String? matriculaCadastrada,
    DocumentoOcrProgressCallback? onProgress,
  }) async {
    onProgress?.call('preprocessing image', 0.05);
    await _yieldToUi();

    final loaded = DocumentoImageLoader.load(imageBytes);
    final decodedOriginal = loaded.decoded;
    final preprocessSteps = <DocumentoPreprocessStep>[];

    onProgress?.call('checking quality', 0.08);
    await _yieldToUi();

    final quality = DocumentoQualityGate.check(decodedOriginal);
    if (!quality.isAcceptable) {
      throw DocumentoQualityException(quality);
    }

    preprocessSteps.add(
      DocumentoPreprocessDebug.fromImage(
        'loaded',
        '1. Carregada (EXIF)',
        decodedOriginal,
        detail: 'Nitidez ${quality.laplacianVariance.toStringAsFixed(0)} · '
            'Luminância ${quality.meanLuminance.toStringAsFixed(0)}',
      ),
    );

    onProgress?.call('detecting orientation', 0.10);
    await _yieldToUi();

    if (kIsWeb) {
      await WebScriptLoader.ensureOcrScriptsLoaded();
    }

    final needsFlip = await DocumentoOrientationDetector.detectFlip(decodedOriginal);
    var oriented = needsFlip
        ? DocumentoImagePreprocess.rotate180(decodedOriginal)
        : decodedOriginal;

    preprocessSteps.add(
      DocumentoPreprocessDebug.fromImage(
        'oriented',
        '2. Orientação',
        oriented,
        detail: needsFlip
            ? 'Rotação 180° aplicada (rosto de cabeça para baixo)'
            : 'Sem rotação (fallback multi-orientação se necessário)',
      ),
    );

    onProgress?.call('cropping document', 0.12);
    await _yieldToUi();

    final cropResult = await DocumentoAutoCrop.tryCropAndWarp(oriented);

    preprocessSteps.add(
      DocumentoPreprocessDebug.fromImage(
        'crop',
        '3. Crop / perspectiva',
        cropResult.image,
        detail: cropResult.wasCropped
            ? 'Contorno detectado — warp aplicado'
            : 'Sem crop (OpenCV indisponível ou contorno não encontrado)',
      ),
    );

    onProgress?.call('enhancing image', 0.14);
    await _yieldToUi();

    final base = DocumentoImagePreprocess.prepare(cropResult.image);

    preprocessSteps.add(
      DocumentoPreprocessDebug.fromImage(
        'prepared',
        '4. Enviada ao Vision',
        base,
        detail: '${base.width}×${base.height}px · escala de cinza · CLAHE · sharpen',
      ),
    );

    final scaleToOriginalX = decodedOriginal.width / base.width;
    final scaleToOriginalY = decodedOriginal.height / base.height;

    onProgress?.call('recognizing google vision', 0.15);
    await _yieldToUi();

    final vision = await _collectVisionScans(
      visionRepository: visionRepository,
      ocrImage: base,
      scaleToOriginalX: scaleToOriginalX,
      scaleToOriginalY: scaleToOriginalY,
      forcaSigla: forcaSigla,
      tipoDocumento: tipoDocumento,
      nomeCadastrado: nomeCadastrado,
      matriculaCadastrada: matriculaCadastrada,
    );

    onProgress?.call('merging orientations', 0.85);
    await _yieldToUi();

    final merged = DocumentoOcrOrientacaoMerge.merge(
      vision.scans,
      forcaSigla: forcaSigla,
      tipoDocumento: tipoDocumento,
      nomeCadastrado: nomeCadastrado,
      matriculaCadastrada: matriculaCadastrada,
    );

    onProgress?.call('done', 1.0);

    final auditBytes = Uint8List.fromList(
      img.encodeJpg(decodedOriginal, quality: 90),
    );

    final rawText = _resolveRawText(
      apiText: vision.rawText,
      scans: vision.scans,
    );

    return DocumentoOcrPipeline.buildResult(
      decoded: decodedOriginal,
      blocks: merged.blocks,
      fields: merged.fields,
      auditBytes: auditBytes,
      visionRawText: rawText,
      imageWasCompressed: loaded.wasCompressed,
      originalImageSizeLabel: loaded.sizeLabel,
      preprocessSteps: preprocessSteps,
    );
  }

  static Future<
      ({
        List<OrientedOcrScan> scans,
        ExtractedVerificationFields? fields,
        String? rawText,
      })> _collectVisionScans({
    required VerificacaoOcrRepository visionRepository,
    required img.Image ocrImage,
    required double scaleToOriginalX,
    required double scaleToOriginalY,
    String? forcaSigla,
    String? tipoDocumento,
    String? nomeCadastrado,
    String? matriculaCadastrada,
  }) async {
    final ocrBytes = DocumentoImagePreprocess.encodeJpeg(ocrImage, quality: 90);
    final recognized = await visionRepository.recognizeWithGoogleVision(ocrBytes);

    final orientations = {
      ...recognized.lines.map((l) => l.orientation),
      ...recognized.words.map((w) => w.orientation),
    };
    if (orientations.isEmpty) orientations.add(0);

    final scans = <OrientedOcrScan>[];
    for (final orientation in orientations) {
      final rotation = orientation;

      List<({String text, Rect rect})> inTextSpace(
        Iterable<({String text, Rect rect, int orientation})> items,
      ) {
        return OcrOrientacaoMapper.mapLinesFromBase(
          lines: items
              .where((item) => item.orientation == orientation)
              .map((item) => (text: item.text, rect: item.rect))
              .toList(),
          angle: rotation,
          baseWidth: ocrImage.width,
          baseHeight: ocrImage.height,
        );
      }

      final lines = inTextSpace(recognized.lines);
      if (lines.isEmpty) continue;

      scans.add(
        DocumentoOcrOrientacaoMerge.buildScan(
          angle: rotation,
          rawLines: lines,
          rawWords: inTextSpace(recognized.words),
          baseWidth: ocrImage.width,
          baseHeight: ocrImage.height,
          scaleToOriginalX: scaleToOriginalX,
          scaleToOriginalY: scaleToOriginalY,
          forcaSigla: forcaSigla,
          tipoDocumento: tipoDocumento,
          nomeCadastrado: nomeCadastrado,
          matriculaCadastrada: matriculaCadastrada,
        ),
      );
    }

    final fields = scans.isEmpty
        ? null
        : DocumentoOcrOrientacaoMerge.merge(
            scans,
            forcaSigla: forcaSigla,
            tipoDocumento: tipoDocumento,
            nomeCadastrado: nomeCadastrado,
            matriculaCadastrada: matriculaCadastrada,
          ).fields;

    return (
      scans: scans,
      fields: fields,
      rawText: _resolveRawText(apiText: recognized.rawText, scans: scans),
    );
  }

  static String? _resolveRawText({
    required String? apiText,
    required List<OrientedOcrScan> scans,
  }) {
    final trimmedApi = apiText?.trim();
    if (trimmedApi != null && trimmedApi.isNotEmpty) return trimmedApi;

    final fromLines = scans
        .expand((scan) => scan.lines.map((line) => line.text.trim()))
        .where((text) => text.isNotEmpty)
        .toSet()
        .join('\n');
    return fromLines.isEmpty ? null : fromLines;
  }
}
