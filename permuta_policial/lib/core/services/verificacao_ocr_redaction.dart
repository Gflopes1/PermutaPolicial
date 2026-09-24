import 'dart:typed_data';

import 'dart:ui';



import 'package:image/image.dart' as img;



enum OcrBlockCategory {

  sensitive,

  nome,

  matricula,

  forca,

  cargo,

  other,

}



class OcrTextBlock {

  final String text;

  final Rect rect;

  final OcrBlockCategory category;



  const OcrTextBlock({

    required this.text,

    required this.rect,

    required this.category,

  });

}



class ExtractedVerificationFields {

  final String? nome;

  final String? matricula;

  final String? forca;

  final String? cargo;



  const ExtractedVerificationFields({

    this.nome,

    this.matricula,

    this.forca,

    this.cargo,

  });



  Map<String, String> toPayload(String tipoDocumento) {

    return {

      'tipo_documento': tipoDocumento,

      if (nome != null && nome!.isNotEmpty) 'nome_extraido': nome!,

      if (matricula != null && matricula!.isNotEmpty) 'matricula_extraida': matricula!,

      if (forca != null && forca!.isNotEmpty) 'forca_extraida': forca!,

      if (cargo != null && cargo!.isNotEmpty) 'cargo_extraido': cargo!,

    };

  }

}



class VerificacaoOcrRedaction {

  static final _moneyPattern = RegExp(r'R\$\s?[\d.,]+', caseSensitive: false);

  static final _cpfPattern = RegExp(r'\d{3}\.\d{3}\.\d{3}-\d{2}');

  static final _bankPattern = RegExp(

    r'(ag[eê]ncia|conta|banco|pix)\s*[:\-]?\s*[\d./\-Xx]+',

    caseSensitive: false,

  );

  static final _addressPattern = RegExp(

    r'\b(rua|avenida|av\.|travessa|alameda|rodovia|cep)\b',

    caseSensitive: false,

  );



  /// Validação em nível de bloco/palavra — usada só como complemento à extração

  /// por âncoras (ex.: valor monetário em linha mista no contracheque).

  static OcrBlockCategory classifyBlock(String text, {String? forcaSigla}) {

    if (_isSensitiveText(text)) {

      return OcrBlockCategory.sensitive;

    }

    return OcrBlockCategory.other;

  }



  static bool _isSensitiveText(String text) {

    return _moneyPattern.hasMatch(text) ||

        _cpfPattern.hasMatch(text) ||

        _bankPattern.hasMatch(text) ||

        _addressPattern.hasMatch(text);

  }



  static img.Image redactImage(img.Image source, List<OcrTextBlock> blocks) {

    final copy = img.Image.from(source);

    for (final block in blocks.where((b) => b.category == OcrBlockCategory.sensitive)) {

      final left = block.rect.left.clamp(0, copy.width - 1).round();

      final top = block.rect.top.clamp(0, copy.height - 1).round();

      final right = block.rect.right.clamp(0, copy.width).round();

      final bottom = block.rect.bottom.clamp(0, copy.height).round();

      img.fillRect(

        copy,

        x1: left,

        y1: top,

        x2: right,

        y2: bottom,

        color: img.ColorRgb8(0, 0, 0),

      );

    }

    return copy;

  }



  static Uint8List encodeJpeg(img.Image image) {

    return Uint8List.fromList(img.encodeJpg(image, quality: 88));

  }



  static bool sensitiveRegionsAreRedacted(

    Uint8List redactedBytes,

    List<OcrTextBlock> sensitiveBlocks,

  ) {

    final decoded = img.decodeImage(redactedBytes);

    if (decoded == null) return false;



    for (final block in sensitiveBlocks) {

      final left = block.rect.left.round().clamp(0, decoded.width - 1);

      final top = block.rect.top.round().clamp(0, decoded.height - 1);

      final right = block.rect.right.round().clamp(left + 1, decoded.width);

      final bottom = block.rect.bottom.round().clamp(top + 1, decoded.height);



      var darkPixels = 0;

      var total = 0;

      for (var y = top; y < bottom; y += 2) {

        for (var x = left; x < right; x += 2) {

          final pixel = decoded.getPixel(x, y);

          if (pixel.r < 30 && pixel.g < 30 && pixel.b < 30) darkPixels++;

          total++;

        }

      }

      if (total == 0 || darkPixels / total < 0.6) {

        return false;

      }

    }

    return true;

  }

}


