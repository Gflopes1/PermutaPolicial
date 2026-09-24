(function () {
  'use strict';

  function bytesToDataUrl(bytes, mime) {
    var binary = '';
    var chunk = 0x8000;
    for (var i = 0; i < bytes.length; i += chunk) {
      binary += String.fromCharCode.apply(null, bytes.subarray(i, i + chunk));
    }
    return 'data:' + (mime || 'image/jpeg') + ';base64,' + btoa(binary);
  }

  function dataUrlToBytes(dataUrl) {
    var parts = String(dataUrl || '').split(',');
    var base64 = parts[1] || '';
    var binary = atob(base64);
    var len = binary.length;
    var bytes = new Uint8Array(len);
    for (var i = 0; i < len; i++) {
      bytes[i] = binary.charCodeAt(i);
    }
    return bytes;
  }

  function mapBox(item) {
    var bbox = item && item.bbox ? item.bbox : item;
    return {
      text: (item && item.text) ? String(item.text).trim() : '',
      x0: Number(bbox.x0 || 0),
      y0: Number(bbox.y0 || 0),
      x1: Number(bbox.x1 || 0),
      y1: Number(bbox.y1 || 0),
    };
  }

  /** Estima bbox por palavra dentro da linha quando o Tesseract não retorna words. */
  function wordsFromLine(line) {
    var mapped = mapBox(line);
    var text = mapped.text;
    if (!text) return [];

    var parts = text.split(/\s+/).filter(Boolean);
    if (parts.length <= 1) {
      return [mapped];
    }

    var lineWidth = mapped.x1 - mapped.x0;
    var totalChars = text.length;
    var cursor = 0;
    var words = [];

    for (var i = 0; i < parts.length; i++) {
      var part = parts[i];
      var start = text.indexOf(part, cursor);
      if (start < 0) start = cursor;
      cursor = start + part.length;

      var startRatio = start / totalChars;
      var endRatio = (start + part.length) / totalChars;

      words.push({
        text: part,
        x0: mapped.x0 + lineWidth * startRatio,
        y0: mapped.y0,
        x1: mapped.x0 + lineWidth * endRatio,
        y1: mapped.y1,
      });
    }

    return words;
  }

  /** Extrai linhas e palavras com bbox a partir da hierarquia blocks → paragraphs → lines → words. */
  function flattenLayout(data) {
    var lines = [];
    var words = [];
    var seenLine = {};
    var seenWord = {};

    function pushLine(line) {
      var mapped = mapBox(line);
      if (!mapped.text) return;
      var key = mapped.text + '|' + mapped.x0 + '|' + mapped.y0;
      if (seenLine[key]) return;
      seenLine[key] = true;
      lines.push(mapped);

      var lineWords = (line.words || []).map(mapBox).filter(function (w) { return w.text; });
      if (lineWords.length === 0) {
        lineWords = wordsFromLine(line);
      }
      for (var i = 0; i < lineWords.length; i++) {
        var w = lineWords[i];
        var wKey = w.text + '|' + w.x0 + '|' + w.y0;
        if (seenWord[wKey]) continue;
        seenWord[wKey] = true;
        words.push(w);
      }
    }

    if (data.blocks && data.blocks.length) {
      for (var b = 0; b < data.blocks.length; b++) {
        var block = data.blocks[b];
        if (block.lines && block.lines.length) {
          for (var li = 0; li < block.lines.length; li++) {
            pushLine(block.lines[li]);
          }
        }
        var paragraphs = block.paragraphs || [];
        for (var p = 0; p < paragraphs.length; p++) {
          var para = paragraphs[p];
          var paraLines = para.lines || [];
          for (var pl = 0; pl < paraLines.length; pl++) {
            pushLine(paraLines[pl]);
          }
        }
      }
    }

    if (data.lines && data.lines.length) {
      for (var dl = 0; dl < data.lines.length; dl++) {
        pushLine(data.lines[dl]);
      }
    }

    if (data.words && data.words.length) {
      for (var dw = 0; dw < data.words.length; dw++) {
        var mappedWord = mapBox(data.words[dw]);
        if (!mappedWord.text) continue;
        var wordKey = mappedWord.text + '|' + mappedWord.x0 + '|' + mappedWord.y0;
        if (seenWord[wordKey]) continue;
        seenWord[wordKey] = true;
        words.push(mappedWord);
      }
    }

    return { lines: lines, words: words };
  }

  async function recognizeImage(dataUrl, lang, onProgress) {
    if (typeof Tesseract === 'undefined') {
      throw new Error('Tesseract.js não foi carregado. Recarregue a página.');
    }

    var worker = await Tesseract.createWorker(lang || 'por', 1, {
      logger: function (m) {
        if (typeof onProgress === 'function' && m) {
          try {
            onProgress(m.status || 'processando', m.progress || 0);
          } catch (_) {}
        }
      },
    });

    try {
      await worker.setParameters({
        tessedit_pageseg_mode: '3',
      });

      var result = await worker.recognize(dataUrl, {}, { blocks: true, text: true });
      var layout = flattenLayout(result.data || {});

      return JSON.stringify({
        text: result.data.text || '',
        words: layout.words,
        lines: layout.lines,
      });
    } finally {
      await worker.terminate();
    }
  }

  async function redactImage(dataUrl, boxes) {
    var img = new Image();
    await new Promise(function (resolve, reject) {
      img.onload = function () { resolve(); };
      img.onerror = function () { reject(new Error('Falha ao carregar imagem para redação.')); };
      img.src = dataUrl;
    });

    var canvas = document.createElement('canvas');
    canvas.width = img.naturalWidth || img.width;
    canvas.height = img.naturalHeight || img.height;
    var ctx = canvas.getContext('2d');
    ctx.drawImage(img, 0, 0);
    ctx.fillStyle = '#000000';

    (boxes || []).forEach(function (b) {
      var x0 = Math.max(0, Number(b.x0 || 0));
      var y0 = Math.max(0, Number(b.y0 || 0));
      var x1 = Math.min(canvas.width, Number(b.x1 || 0));
      var y1 = Math.min(canvas.height, Number(b.y1 || 0));
      if (x1 <= x0 || y1 <= y0) return;
      ctx.fillRect(x0, y0, x1 - x0, y1 - y0);
    });

    return canvas.toDataURL('image/jpeg', 0.88);
  }

  globalThis.permutaOcrBridge = {
    recognizeImage: recognizeImage,
    redactImage: redactImage,
    bytesToDataUrl: bytesToDataUrl,
    dataUrlToBytes: dataUrlToBytes,
  };
})();
