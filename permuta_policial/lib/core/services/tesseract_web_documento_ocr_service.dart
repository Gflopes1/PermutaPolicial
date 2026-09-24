import 'dart:typed_data';

import '../api/repositories/verificacao_ocr_repository.dart';
import 'documento_ocr_coordinator.dart';
import 'documento_ocr_types.dart';

export 'documento_ocr_types.dart';
export 'verificacao_ocr_redaction.dart';

/// OCR web via Google Vision (servidor).
class DocumentoOcrService {
  DocumentoOcrService._({required this.visionRepository});

  final VerificacaoOcrRepository visionRepository;

  static bool get isSupported => true;

  static DocumentoOcrService create({VerificacaoOcrRepository? visionRepository}) {
    if (visionRepository == null) {
      throw StateError('Google Vision requer VerificacaoOcrRepository configurado.');
    }
    return DocumentoOcrService._(visionRepository: visionRepository);
  }

  Future<DocumentoOcrResult> processarDocumento({
    required Uint8List imageBytes,
    String? filePath,
    String? forcaSigla,
    String? tipoDocumento,
    String? nomeCadastrado,
    String? matriculaCadastrada,
    DocumentoOcrProgressCallback? onProgress,
  }) {
    return DocumentoOcrCoordinator.process(
      imageBytes: imageBytes,
      visionRepository: visionRepository,
      forcaSigla: forcaSigla,
      tipoDocumento: tipoDocumento,
      nomeCadastrado: nomeCadastrado,
      matriculaCadastrada: matriculaCadastrada,
      onProgress: onProgress,
    );
  }
}

typedef VerificacaoOcrService = DocumentoOcrService;
typedef VerificacaoOcrProcessResult = DocumentoOcrResult;
