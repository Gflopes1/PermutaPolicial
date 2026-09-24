/**
 * Logs de debug OCR — sempre vão para stdout/stderr (console),
 * sem depender de logger.isDevLogging (silenciado em ENV=prod).
 *
 * Ativar em produção: VERIFICACAO_OCR_VISION_LOG=1 no .env
 */

function isOcrDebugEnabled() {
  const explicit =
    process.env.VERIFICACAO_OCR_VISION_LOG === '1' ||
    process.env.VERIFICACAO_OCR_VISION_LOG === 'true' ||
    process.env.VERIFICACAO_OCR_LOG === '1' ||
    process.env.VERIFICACAO_OCR_LOG === 'true';
  if (explicit) return true;
  if (process.env.ENV === 'prod') return false;
  return process.env.NODE_ENV !== 'production';
}

function isOcrDebugVerbose() {
  return (
    process.env.VERIFICACAO_OCR_VISION_LOG === '1' ||
    process.env.VERIFICACAO_OCR_VISION_LOG === 'true'
  );
}

function ocrDebugLog(message, data = {}, level = 'INFO') {
  if (!isOcrDebugEnabled()) return;

  const entry = {
    timestamp: new Date().toISOString(),
    level,
    scope: 'verificacao-ocr',
    message,
    ...(data && typeof data === 'object' ? data : { detail: data }),
  };

  const line = JSON.stringify(entry);
  if (level === 'ERROR') {
    console.error(line);
  } else {
    console.log(line);
  }
}

function truncateOcrText(value, maxLen = 12000) {
  const text = String(value || '');
  if (text.length <= maxLen) return text;
  return `${text.slice(0, maxLen)}… [truncado, ${text.length} chars total]`;
}

module.exports = {
  isOcrDebugEnabled,
  isOcrDebugVerbose,
  ocrDebugLog,
  truncateOcrText,
};
