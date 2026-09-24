const axios = require('axios');
const ApiError = require('../../core/utils/ApiError');
const {
  getAccessTokenForScopes,
  isServiceAccountConfigured,
} = require('../push/fcm-v1.client');
const {
  isOcrDebugVerbose,
  ocrDebugLog,
  truncateOcrText,
} = require('./verificacao-ocr-debug');

function summarizeVisionLayout(layout) {
  const orientations = [...new Set((layout?.lines || []).map((line) => line.orientation))];
  return {
    wordCount: layout?.words?.length || 0,
    lineCount: layout?.lines?.length || 0,
    orientations,
  };
}

const VISION_SCOPE = 'https://www.googleapis.com/auth/cloud-vision';
const VISION_URL = 'https://vision.googleapis.com/v1/images:annotate';

function getVisionApiKey() {
  return (
    process.env.GOOGLE_VISION_API_KEY ||
    process.env.FIREBASE_WEB_API_KEY ||
    ''
  ).trim();
}

function verticesToBox(vertices) {
  if (!Array.isArray(vertices) || vertices.length === 0) {
    return { x0: 0, y0: 0, x1: 0, y1: 0 };
  }
  const xs = vertices.map((v) => Number(v.x || 0));
  const ys = vertices.map((v) => Number(v.y || 0));
  return {
    x0: Math.min(...xs),
    y0: Math.min(...ys),
    x1: Math.max(...xs),
    y1: Math.max(...ys),
  };
}

/**
 * Direção de leitura da palavra, em graus no sentido horário a partir da
 * horizontal. O Vision ordena os vértices no sentido do texto, então o vetor
 * vertice[0] -> vertice[1] aponta para onde a palavra é lida.
 *
 * Necessário porque a carteira funcional tem faces com texto vertical
 * (nome/posto) e faces com texto horizontal (Id. funcional).
 */
function orientationFromVertices(vertices) {
  if (!Array.isArray(vertices) || vertices.length < 2) return 0;
  const dx = Number(vertices[1].x || 0) - Number(vertices[0].x || 0);
  const dy = Number(vertices[1].y || 0) - Number(vertices[0].y || 0);
  if (Math.abs(dx) >= Math.abs(dy)) return dx >= 0 ? 0 : 180;
  return dy >= 0 ? 90 : 270;
}

/** Coordenadas no espaço de leitura: u avança na direção do texto, v entre linhas. */
function toTextSpace(box, orientation) {
  const centerX = (box.x0 + box.x1) / 2;
  const centerY = (box.y0 + box.y1) / 2;
  switch (orientation) {
    case 90:
      return { u: centerY, v: -centerX, thickness: box.x1 - box.x0 };
    case 180:
      return { u: -centerX, v: -centerY, thickness: box.y1 - box.y0 };
    case 270:
      return { u: -centerY, v: centerX, thickness: box.x1 - box.x0 };
    default:
      return { u: centerX, v: centerY, thickness: box.y1 - box.y0 };
  }
}

/**
 * Extensão de cada palavra ao longo do eixo de leitura (uMin/uMax) e no eixo
 * perpendicular (v). Necessário para detectar gaps grandes entre clusters de
 * campo em texto vertical (90/270).
 */
function wordReadingExtents(word, orientation) {
  switch (orientation) {
    case 90:
      return {
        uMin: word.y0,
        uMax: word.y1,
        v: -((word.x0 + word.x1) / 2),
        readExtent: word.y1 - word.y0,
        crossExtent: word.x1 - word.x0,
      };
    case 270:
      return {
        uMin: -word.y1,
        uMax: -word.y0,
        v: (word.x0 + word.x1) / 2,
        readExtent: word.y1 - word.y0,
        crossExtent: word.x1 - word.x0,
      };
    case 180:
      return {
        uMin: -word.x1,
        uMax: -word.x0,
        v: -((word.y0 + word.y1) / 2),
        readExtent: word.x1 - word.x0,
        crossExtent: word.y1 - word.y0,
      };
    default:
      return {
        uMin: word.x0,
        uMax: word.x1,
        v: (word.y0 + word.y1) / 2,
        readExtent: word.x1 - word.x0,
        crossExtent: word.y1 - word.y0,
      };
  }
}

function clusterWordsByPerpendicularAxis(words, orientation) {
  const groups = [];

  for (const word of words) {
    const { v, crossExtent } = wordReadingExtents(word, orientation);
    const tolerance = Math.max(crossExtent, 10) * 0.55;
    let group = groups.find((g) => Math.abs(g.v - v) <= tolerance);

    if (!group) {
      group = { words: [], v };
      groups.push(group);
    }

    group.words.push(word);
    group.v =
      group.words.reduce(
        (sum, item) => sum + wordReadingExtents(item, orientation).v,
        0
      ) / group.words.length;
  }

  groups.sort((a, b) => a.v - b.v);
  return groups;
}

/**
 * Em 90/270, palavras na mesma coluna (v) podem ser campos distintos separados
 * por um gap grande no eixo de leitura — ex.: Id. Funcional vs Data de Nasc.
 */
function splitWordsByReadingGap(words, orientation) {
  if (orientation !== 90 && orientation !== 270) {
    return [words];
  }
  if (words.length <= 1) {
    return [words];
  }

  const sorted = [...words].sort(
    (a, b) =>
      wordReadingExtents(a, orientation).uMin - wordReadingExtents(b, orientation).uMin
  );

  const avgReadExtent =
    sorted.reduce(
      (sum, word) => sum + wordReadingExtents(word, orientation).readExtent,
      0
    ) / sorted.length;
  // ~1–1.5× a extensão média da palavra; 1.15 separa clusters reais (~140px+)
  // sem partir palavras do mesmo rótulo/valor (espaçamento interno menor).
  const gapThreshold = Math.max(12, avgReadExtent * 1.15);

  const segments = [];
  let current = [sorted[0]];

  for (let i = 1; i < sorted.length; i += 1) {
    const prev = wordReadingExtents(sorted[i - 1], orientation);
    const next = wordReadingExtents(sorted[i], orientation);
    const gap = next.uMin - prev.uMax;

    if (gap > gapThreshold) {
      segments.push(current);
      current = [sorted[i]];
    } else {
      current.push(sorted[i]);
    }
  }

  segments.push(current);
  return segments;
}

function buildLineFromWords(words, orientation) {
  const sorted = [...words].sort(
    (a, b) =>
      wordReadingExtents(a, orientation).uMin - wordReadingExtents(b, orientation).uMin
  );

  return {
    text: sorted.map((word) => word.text).join(' ').trim(),
    x0: Math.min(...sorted.map((word) => word.x0)),
    y0: Math.min(...sorted.map((word) => word.y0)),
    x1: Math.max(...sorted.map((word) => word.x1)),
    y1: Math.max(...sorted.map((word) => word.y1)),
    orientation,
  };
}

function extractWords(fullTextAnnotation) {
  const words = [];
  const seenWords = new Set();

  for (const page of fullTextAnnotation?.pages || []) {
    for (const block of page.blocks || []) {
      for (const paragraph of block.paragraphs || []) {
        for (const word of paragraph.words || []) {
          const text = (word.symbols || [])
            .map((s) => s.text || '')
            .join('')
            .trim();
          if (!text) continue;
          const vertices = word.boundingBox?.vertices;
          const box = verticesToBox(vertices);
          const orientation = orientationFromVertices(vertices);
          const wordKey = `${text}|${box.x0}|${box.y0}`;
          if (!seenWords.has(wordKey)) {
            seenWords.add(wordKey);
            words.push({ text, ...box, orientation });
          }
        }
      }
    }
  }

  return words;
}

/**
 * Agrupa palavras em linhas ao longo da própria direção de leitura, separando
 * blocos horizontais de blocos verticais. Retorna retângulos alinhados aos
 * eixos da imagem (o cliente rotaciona depois, conforme a orientação).
 */
function groupWordsIntoLines(words) {
  if (!words.length) return [];

  const lines = [];

  for (const orientation of [0, 90, 180, 270]) {
    const bucket = words.filter((w) => w.orientation === orientation);
    if (!bucket.length) continue;

    const vGroups = clusterWordsByPerpendicularAxis(bucket, orientation);

    for (const vGroup of vGroups) {
      const segments = splitWordsByReadingGap(vGroup.words, orientation);
      for (const segment of segments) {
        lines.push(buildLineFromWords(segment, orientation));
      }
    }
  }

  return lines;
}

function flattenVisionAnnotation(fullTextAnnotation) {
  const words = extractWords(fullTextAnnotation);
  const lines = groupWordsIntoLines(words);
  return { lines, words };
}

async function getVisionAuthHeaders() {
  if (isServiceAccountConfigured()) {
    const accessToken = await getAccessTokenForScopes([VISION_SCOPE]);
    return {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    };
  }

  const apiKey = getVisionApiKey();
  if (apiKey) {
    return { 'Content-Type': 'application/json', _apiKey: apiKey };
  }

  throw new ApiError(
    503,
    'Google Vision não configurado. Use o mesmo JSON do FCM (FCM_SERVICE_ACCOUNT_PATH ou firebase-service-account.json) ' +
      'e habilite a Cloud Vision API no Google Cloud. Alternativa: GOOGLE_VISION_API_KEY no .env.'
  );
}

async function recognizeDocumentText(imageBuffer) {
  const headers = await getVisionAuthHeaders();
  const apiKey = headers._apiKey;
  delete headers._apiKey;
  const authMode = apiKey ? 'api_key' : 'service_account';

  const base64 = imageBuffer.toString('base64');
  const url = apiKey
    ? `${VISION_URL}?key=${encodeURIComponent(apiKey)}`
    : VISION_URL;

  ocrDebugLog('Google Vision OCR — requisição', {
    authMode,
    imageBytes: imageBuffer?.length || 0,
    base64Chars: base64.length,
    feature: 'DOCUMENT_TEXT_DETECTION',
  });

  let response;
  try {
    response = await axios.post(
      url,
      {
        requests: [
          {
            image: { content: base64 },
            features: [{ type: 'DOCUMENT_TEXT_DETECTION' }],
          },
        ],
      },
      {
        timeout: 60000,
        headers,
        maxBodyLength: 20 * 1024 * 1024,
      }
    );
  } catch (error) {
    ocrDebugLog('Google Vision OCR — falha HTTP', {
      authMode,
      imageBytes: imageBuffer?.length || 0,
      status: error.response?.status,
      statusText: error.response?.statusText,
      googleError: error.response?.data?.error || null,
      responseData: error.response?.data || null,
      message: error.message,
    }, 'ERROR');
    const message =
      error.response?.data?.error?.message ||
      error.message ||
      'Falha ao chamar Google Vision API.';
    throw new ApiError(502, message);
  }

  const annotation = response.data?.responses?.[0];
  if (annotation?.error) {
    ocrDebugLog('Google Vision OCR — erro na resposta', {
      authMode,
      imageBytes: imageBuffer?.length || 0,
      googleError: annotation.error,
      rawResponse: response.data,
    }, 'ERROR');
    throw new ApiError(502, annotation.error.message || 'Erro na Google Vision API.');
  }

  const fullText = annotation.fullTextAnnotation?.text || '';
  const layout = flattenVisionAnnotation(annotation.fullTextAnnotation);
  const lineText = layout.lines.map((line) => line.text).filter(Boolean).join('\n');
  const resolvedText = fullText || lineText || '';

  const allLines = layout.lines.map((line) => ({
    orientation: line.orientation,
    text: line.text,
    x0: line.x0,
    y0: line.y0,
    x1: line.x1,
    y1: line.y1,
  }));

  ocrDebugLog('Google Vision OCR — resposta processada (linhas que o app recebe)', {
    authMode,
    imageBytes: imageBuffer?.length || 0,
    hasFullTextAnnotation: !!annotation.fullTextAnnotation,
    fullTextLength: fullText.length,
    resolvedTextLength: resolvedText.length,
    usedLineFallback: !fullText && !!lineText,
    ...summarizeVisionLayout(layout),
    lines: allLines,
    text: truncateOcrText(resolvedText),
    rawFullText: isOcrDebugVerbose() ? truncateOcrText(fullText, 50000) : undefined,
  });

  if (!resolvedText.trim() && layout.lines.length === 0) {
    ocrDebugLog('Google Vision OCR — nenhum texto reconhecido', {
      authMode,
      imageBytes: imageBuffer?.length || 0,
      responseKeys: Object.keys(annotation || {}),
      textAnnotationsCount: annotation?.textAnnotations?.length || 0,
      rawResponse: isOcrDebugVerbose() ? response.data : undefined,
    }, 'ERROR');
  }

  return {
    engine: 'google_vision',
    text: resolvedText,
    lines: layout.lines,
    words: layout.words,
  };
}

module.exports = {
  recognizeDocumentText,
  getVisionApiKey,
  flattenVisionAnnotation,
  groupWordsIntoLines,
  splitWordsByReadingGap,
  wordReadingExtents,
};
