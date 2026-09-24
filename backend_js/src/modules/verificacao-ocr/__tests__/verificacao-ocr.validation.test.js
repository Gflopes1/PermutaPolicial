const { Segments } = require('celebrate');
const verificacaoOcrValidation = require('../verificacao-ocr.validation');

describe('verificacao-ocr.validation submitOcr', () => {
  const schema = verificacaoOcrValidation.submitOcr[Segments.BODY];

  it('aceita ocr_raw_text grande enviado pelo app', () => {
    const { error } = schema.validate({
      tipo_documento: 'funcional',
      nome_extraido: 'JOSE DA SILVA',
      matricula_extraida: '123456789012',
      ocr_raw_text: 'PORTADOR JOSE DA SILVA Id Funcional 123456789012',
    });
    expect(error).toBeUndefined();
  });

  it('rejeita tipo_documento inválido', () => {
    const { error } = schema.validate({
      tipo_documento: 'rg',
      ocr_raw_text: 'texto',
    });
    expect(error).toBeDefined();
  });
});
