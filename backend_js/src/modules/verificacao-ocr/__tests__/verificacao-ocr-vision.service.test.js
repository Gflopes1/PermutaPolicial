const { flattenVisionAnnotation } = require('../verificacao-ocr-vision.service');

/**
 * O Vision ordena os vértices no sentido da leitura, então `direction` define
 * para onde a palavra é lida: 0 = direita, 90 = para baixo.
 */
function buildWord(text, { x, y, width, height, direction }) {
  let vertices;
  if (direction === 90) {
    vertices = [
      { x: x + width, y },
      { x: x + width, y: y + height },
      { x, y: y + height },
      { x, y },
    ];
  } else if (direction === 270) {
    vertices = [
      { x: x + width, y: y + height },
      { x: x + width, y },
      { x, y },
      { x, y: y + height },
    ];
  } else {
    vertices = [
      { x, y },
      { x: x + width, y },
      { x: x + width, y: y + height },
      { x, y: y + height },
    ];
  }

  return {
    symbols: text.split('').map((char) => ({ text: char })),
    boundingBox: { vertices },
  };
}

function buildAnnotation(words) {
  return { pages: [{ blocks: [{ paragraphs: [{ words }] }] }] };
}

describe('flattenVisionAnnotation', () => {
  it('separa bloco vertical de bloco horizontal na mesma imagem', () => {
    // Carteira funcional: nome/posto na face vertical, Id. funcional na horizontal.
    const annotation = buildAnnotation([
      buildWord('Portador', { x: 300, y: 100, width: 20, height: 90, direction: 90 }),
      buildWord('JOSE', { x: 270, y: 100, width: 20, height: 60, direction: 90 }),
      buildWord('DA', { x: 270, y: 170, width: 20, height: 30, direction: 90 }),
      buildWord('SILVA', { x: 270, y: 210, width: 20, height: 70, direction: 90 }),
      buildWord('Id.', { x: 400, y: 500, width: 30, height: 20, direction: 0 }),
      buildWord('Funcional', { x: 440, y: 500, width: 90, height: 20, direction: 0 }),
      buildWord('1234567', { x: 540, y: 500, width: 80, height: 20, direction: 0 }),
    ]);

    const { lines, words } = flattenVisionAnnotation(annotation);

    expect(words).toHaveLength(7);
    expect(words.filter((w) => w.orientation === 90)).toHaveLength(4);
    expect(words.filter((w) => w.orientation === 0)).toHaveLength(3);

    const horizontais = lines.filter((l) => l.orientation === 0);
    expect(horizontais.map((l) => l.text)).toEqual(['Id. Funcional 1234567']);

    // Palavras verticais viram linhas próprias, na ordem de leitura do bloco.
    const verticais = lines.filter((l) => l.orientation === 90);
    expect(verticais.map((l) => l.text)).toEqual(['Portador', 'JOSE DA SILVA']);
  });

  it('não junta palavras de linhas diferentes do mesmo bloco horizontal', () => {
    const annotation = buildAnnotation([
      buildWord('Nome', { x: 100, y: 100, width: 60, height: 20, direction: 0 }),
      buildWord('MARIA', { x: 100, y: 140, width: 80, height: 20, direction: 0 }),
    ]);

    const { lines } = flattenVisionAnnotation(annotation);

    expect(lines.map((l) => l.text)).toEqual(['Nome', 'MARIA']);
  });

  it('separa clusters de campos distintos no verso vertical (90°)', () => {
    // Mesma coluna (x≈300), gaps ~150px entre rótulos de campos diferentes.
    const annotation = buildAnnotation([
      buildWord('Id.', { x: 300, y: 100, width: 20, height: 40, direction: 90 }),
      buildWord('Funcional', { x: 300, y: 145, width: 20, height: 80, direction: 90 }),
      buildWord('G.', { x: 300, y: 380, width: 20, height: 30, direction: 90 }),
      buildWord('Sang/Fator', { x: 300, y: 415, width: 20, height: 100, direction: 90 }),
      buildWord('RH', { x: 300, y: 520, width: 20, height: 40, direction: 90 }),
      buildWord('Data', { x: 300, y: 710, width: 20, height: 50, direction: 90 }),
      buildWord('de', { x: 300, y: 765, width: 20, height: 30, direction: 90 }),
      buildWord('Nasc', { x: 300, y: 800, width: 20, height: 50, direction: 90 }),
    ]);

    const { lines } = flattenVisionAnnotation(annotation);
    const verticais = lines.filter((l) => l.orientation === 90);

    expect(verticais.map((l) => l.text)).toEqual([
      'Id. Funcional',
      'G. Sang/Fator RH',
      'Data de Nasc',
    ]);
  });

  it('separa clusters distintos em texto vertical 270°', () => {
    const annotation = buildAnnotation([
      buildWord('CampoA', { x: 200, y: 100, width: 20, height: 80, direction: 270 }),
      buildWord('CampoB', { x: 200, y: 280, width: 20, height: 80, direction: 270 }),
    ]);

    const { lines } = flattenVisionAnnotation(annotation);
    const verticais = lines.filter((l) => l.orientation === 270);

    // 270° lê de baixo para cima: CampoB (y maior) antes de CampoA.
    expect(verticais.map((l) => l.text)).toEqual(['CampoB', 'CampoA']);
  });

  it('devolve listas vazias quando não há anotação', () => {
    expect(flattenVisionAnnotation(undefined)).toEqual({ lines: [], words: [] });
  });
});
