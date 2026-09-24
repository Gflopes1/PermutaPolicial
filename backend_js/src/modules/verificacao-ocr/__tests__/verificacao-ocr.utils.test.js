const {
  namesMatch,
  matriculasMatch,
  evaluateAutoVerification,
} = require('../verificacao-ocr.utils');

describe('verificacao-ocr.utils', () => {
  describe('matriculasMatch', () => {
    it('aceita matrícula esperada dentro de texto com outros números', () => {
      expect(matriculasMatch('1234567', '123456789')).toBe(true);
      expect(matriculasMatch('1234567', 'Id Funcional 1234567 2024')).toBe(true);
    });

    it('ignora pontos e traços', () => {
      expect(matriculasMatch('123.456-7', '1234567')).toBe(true);
    });
  });

  describe('namesMatch', () => {
    it('aceita nome parcial e diferença de maiúsculas', () => {
      expect(namesMatch('Jose da Silva', 'JOSE DA SILVA SANTOS')).toBe(true);
    });

    it('aceita partes do nome espalhadas no corpus OCR', () => {
      const { namePartsMatch } = require('../verificacao-ocr.utils');
      expect(
        namePartsMatch(
          'Maria Oliveira',
          'PORTADOR MARIA OLIVEIRA POSTO CAPITAO'
        )
      ).toBe(true);
    });
  });

  describe('evaluateAutoVerification', () => {
    it('verifica automaticamente quando nome e matrícula estão presentes no OCR', () => {
      const result = evaluateAutoVerification({
        nomeCadastrado: 'Jose da Silva',
        idFuncionalCadastrado: '1234567',
        forcaSigla: 'BMRS',
        nomeExtraido: 'JOSE DA SILVA',
        matriculaExtraida: '123456789012',
      });

      expect(result.nomeOk).toBe(true);
      expect(result.matriculaOk).toBe(true);
      expect(result.autoVerify).toBe(true);
    });

    it('usa texto bruto do OCR quando o campo extraído falha', () => {
      const result = evaluateAutoVerification({
        nomeCadastrado: 'Jose da Silva',
        idFuncionalCadastrado: '1234567',
        forcaSigla: 'BMRS',
        nomeExtraido: null,
        matriculaExtraida: '999999999',
        ocrRawText: 'PORTADOR JOSE DA SILVA Id Funcional 123456789012',
      });

      expect(result.nomeOk).toBe(true);
      expect(result.matriculaOk).toBe(true);
      expect(result.autoVerify).toBe(true);
    });

    it('usa corpus unificado mesmo com matrícula extraída incorreta', () => {
      const result = evaluateAutoVerification({
        nomeCadastrado: 'Jose da Silva',
        idFuncionalCadastrado: '1234567',
        forcaSigla: 'BMRS',
        nomeExtraido: 'PORTADOR',
        matriculaExtraida: '999999999999',
        ocrRawText: 'JOSE DA SILVA\nId Funcional 123456789012',
      });

      expect(result.nomeOk).toBe(true);
      expect(result.matriculaOk).toBe(true);
      expect(result.autoVerify).toBe(true);
    });
  });
});
