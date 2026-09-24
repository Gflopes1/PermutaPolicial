import 'package:flutter_test/flutter_test.dart';
import 'package:permuta_policial/core/services/documento_field_match.dart';

void main() {
  test('matriculaPresent aceita id esperada dentro de outros números', () {
    expect(
      DocumentoFieldMatch.matriculaPresent(
        expected: '1234567',
        extracted: '123456789',
      ),
      isTrue,
    );
    expect(
      DocumentoFieldMatch.matriculaPresent(
        expected: '123.456-7',
        extracted: 'Id Funcional 1234567 2024',
      ),
      isTrue,
    );
  });

  test('nomePresent ignora maiúsculas e acentos', () {
    expect(
      DocumentoFieldMatch.nomePresent(
        expected: 'José da Silva',
        ocrCorpus: 'PORTADOR JOSE DA SILVA SANTOS',
      ),
      isTrue,
    );
  });
}
