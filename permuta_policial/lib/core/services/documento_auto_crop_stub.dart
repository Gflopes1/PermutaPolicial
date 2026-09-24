import 'package:image/image.dart' as img;

class AutoCropResult {
  final img.Image image;
  final bool wasCropped;

  const AutoCropResult({required this.image, required this.wasCropped});
}

/// Stub fora da web — devolve imagem original sem crop.
class DocumentoAutoCrop {
  DocumentoAutoCrop._();

  static Future<AutoCropResult> tryCropAndWarp(img.Image source) async {
    return AutoCropResult(image: source, wasCropped: false);
  }
}
