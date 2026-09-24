import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import '../api/repositories/verificacao_ocr_repository.dart';
import 'documento_image_loader.dart';
import 'documento_image_preprocess.dart';
import 'documento_ocr_engine.dart';
import 'documento_ocr_orientacao.dart';
import 'documento_ocr_pipeline.dart';
import 'documento_ocr_types.dart';

export 'documento_ocr_engine.dart';
export 'documento_ocr_types.dart';
export 'verificacao_ocr_redaction.dart';

/// OCR nativo via ML Kit (Android/iOS).
class DocumentoOcrService {
  DocumentoOcrService._();

  static bool get isSupported => true;

  static DocumentoOcrService create({VerificacaoOcrRepository? visionRepository}) =>
      DocumentoOcrService._();

  Future<DocumentoOcrResult> processarDocumento({
    required Uint8List imageBytes,
    String? filePath,
    String? forcaSigla,
    String? tipoDocumento,
    String? nomeCadastrado,
    String? matriculaCadastrada,
    DocumentoOcrEngineMode engineMode = DocumentoOcrEngineMode.tesseract,
    DocumentoOcrProgressCallback? onProgress,
  }) async {
    onProgress?.call('preprocessing image', 0.05);

    final loaded = DocumentoImageLoader.load(imageBytes);
    final decodedOriginal = loaded.decoded;

    final orientations = DocumentoImagePreprocess.prepareOrientations(decodedOriginal);
    final base = orientations.firstWhere((o) => o.angle == 0).image;
    final scaleToOriginalX = decodedOriginal.width / base.width;
    final scaleToOriginalY = decodedOriginal.height / base.height;

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final scans = <OrientedOcrScan>[];

    try {
      for (var i = 0; i < orientations.length; i++) {
        final entry = orientations[i];
        final progress = 0.1 + (i / orientations.length) * 0.6;
        onProgress?.call('recognizing text ${entry.angle}°', progress);

        final recognized = await _recognize(recognizer: recognizer, image: entry.image);

        scans.add(
          DocumentoOcrOrientacaoMerge.buildScan(
            angle: entry.angle,
            rawLines: recognized.lines,
            rawWords: recognized.words,
            baseWidth: base.width,
            baseHeight: base.height,
            scaleToOriginalX: scaleToOriginalX,
            scaleToOriginalY: scaleToOriginalY,
            forcaSigla: forcaSigla,
            tipoDocumento: tipoDocumento,
            nomeCadastrado: nomeCadastrado,
            matriculaCadastrada: matriculaCadastrada,
          ),
        );
      }
    } finally {
      await recognizer.close();
    }

    onProgress?.call('merging orientations', 0.75);

    final merged = DocumentoOcrOrientacaoMerge.merge(
      scans,
      forcaSigla: forcaSigla,
      tipoDocumento: tipoDocumento,
      nomeCadastrado: nomeCadastrado,
      matriculaCadastrada: matriculaCadastrada,
    );

    onProgress?.call('done', 1.0);

    final auditBytes = Uint8List.fromList(
      img.encodeJpg(decodedOriginal, quality: 90),
    );

    return DocumentoOcrPipeline.buildResult(
      decoded: decodedOriginal,
      blocks: merged.blocks,
      fields: merged.fields,
      auditBytes: auditBytes,
      imageWasCompressed: loaded.wasCompressed,
      originalImageSizeLabel: loaded.sizeLabel,
    );
  }

  Future<DocumentoOcrResult> processImageFile(
    String filePath, {
    String? forcaSigla,
    String? tipoDocumento,
    String? nomeCadastrado,
    String? matriculaCadastrada,
    DocumentoOcrProgressCallback? onProgress,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    return processarDocumento(
      imageBytes: bytes,
      filePath: filePath,
      forcaSigla: forcaSigla,
      tipoDocumento: tipoDocumento,
      nomeCadastrado: nomeCadastrado,
      matriculaCadastrada: matriculaCadastrada,
      onProgress: onProgress,
    );
  }

  static Future<
      ({
        List<({String text, Rect rect})> lines,
        List<({String text, Rect rect})> words,
      })> _recognize({
    required TextRecognizer recognizer,
    required img.Image image,
  }) async {
    final ocrBytes = DocumentoImagePreprocess.encodeJpeg(image);
    final ocrPath = await _writeTempFile(ocrBytes);

    final recognizedText = await recognizer.processImage(
      InputImage.fromFilePath(ocrPath),
    );

    final lines = <({String text, Rect rect})>[];
    final words = <({String text, Rect rect})>[];

    for (final block in recognizedText.blocks) {
      if (block.lines.isNotEmpty) {
        for (final line in block.lines) {
          final text = line.text.trim();
          if (text.isEmpty) continue;
          lines.add((
            text: text,
            rect: _toRect(line.boundingBox, image.width, image.height),
          ));

          for (final element in line.elements) {
            final wordText = element.text.trim();
            if (wordText.isEmpty) continue;
            words.add((
              text: wordText,
              rect: _toRect(element.boundingBox, image.width, image.height),
            ));
          }
        }
      } else {
        final text = block.text.trim();
        if (text.isEmpty) continue;
        lines.add((
          text: text,
          rect: _toRect(block.boundingBox, image.width, image.height),
        ));
      }
    }

    return (lines: lines, words: words);
  }

  static Rect _toRect(Rect box, int imageWidth, int imageHeight) {
    return Rect.fromLTRB(
      box.left.clamp(0, imageWidth.toDouble()),
      box.top.clamp(0, imageHeight.toDouble()),
      box.right.clamp(0, imageWidth.toDouble()),
      box.bottom.clamp(0, imageHeight.toDouble()),
    );
  }

  static Future<String> _writeTempFile(Uint8List bytes) async {
    final temp = File(
      '${Directory.systemTemp.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await temp.writeAsBytes(bytes);
    return temp.path;
  }
}

typedef VerificacaoOcrService = DocumentoOcrService;
typedef VerificacaoOcrProcessResult = DocumentoOcrResult;
