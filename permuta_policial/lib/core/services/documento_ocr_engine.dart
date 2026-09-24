/// Modo de OCR para verificação de documento.
enum DocumentoOcrEngineMode {
  /// Tesseract.js local (web).
  tesseract,

  /// Google Cloud Vision via backend (mesma chave do Firebase/FCM).
  googleVision,

  /// Executa Tesseract e Vision em paralelo e combina o melhor resultado.
  ambos,
}

extension DocumentoOcrEngineModeLabel on DocumentoOcrEngineMode {
  String get label => switch (this) {
        DocumentoOcrEngineMode.tesseract => 'Tesseract (local)',
        DocumentoOcrEngineMode.googleVision => 'Google Vision',
        DocumentoOcrEngineMode.ambos => 'Ambos (teste paralelo)',
      };

  String get description => switch (this) {
        DocumentoOcrEngineMode.tesseract =>
          'OCR no navegador com Tesseract.js — privacidade total, sem enviar imagem para OCR.',
        DocumentoOcrEngineMode.googleVision =>
          'OCR via Google Vision API no servidor (usa o mesmo JSON do FCM; imagem enviada só para reconhecimento).',
        DocumentoOcrEngineMode.ambos =>
          'Roda Tesseract e Google Vision ao mesmo time e combina os campos mais confiáveis.',
      };
}
