// Utilitários de segurança do Mapa Tático

const ApiError = require('../../core/utils/ApiError');

const MAX_GROUP_MEMBERS = 50;
const INVITE_TTL_DAYS = 7;
const REPORT_RATE_LIMIT_HOURS = 24;
const REPORT_RATE_LIMIT_MAX = 3;

// Limites aproximados do território brasileiro (inclui ilhas)
const BR_LAT_MIN = -33.75;
const BR_LAT_MAX = 5.27;
const BR_LNG_MIN = -73.99;
const BR_LNG_MAX = -32.39;

const SENSITIVE_AUDIT_FIELDS = ['lat', 'lng', 'address', 'photo_url', 'description', 'title'];

function normalizeEmail(email) {
  if (!email || typeof email !== 'string') return '';
  return email.toLowerCase().trim();
}

function validateBrazilCoordinates(lat, lng) {
  const latitude = parseFloat(lat);
  const longitude = parseFloat(lng);
  if (Number.isNaN(latitude) || Number.isNaN(longitude)) {
    throw new ApiError(400, 'Coordenadas inválidas.');
  }
  if (
    latitude < BR_LAT_MIN || latitude > BR_LAT_MAX ||
    longitude < BR_LNG_MIN || longitude > BR_LNG_MAX
  ) {
    throw new ApiError(400, 'Coordenadas fora do território brasileiro.');
  }
  return { lat: latitude, lng: longitude };
}

/**
 * Valida magic bytes do buffer (JPEG, PNG, WEBP, HEIC/HEIF).
 * @returns {{ mime: string, ext: string }}
 */
function validateImageMagicBytes(buffer) {
  if (!buffer || buffer.length < 12) {
    throw new ApiError(400, 'Arquivo de imagem inválido ou corrompido.');
  }

  // JPEG: FF D8 FF
  if (buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) {
    return { mime: 'image/jpeg', ext: 'jpg' };
  }
  // PNG: 89 50 4E 47
  if (buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4e && buffer[3] === 0x47) {
    return { mime: 'image/png', ext: 'png' };
  }
  // WEBP: RIFF....WEBP
  if (
    buffer[0] === 0x52 && buffer[1] === 0x49 && buffer[2] === 0x46 && buffer[3] === 0x46 &&
    buffer[8] === 0x57 && buffer[9] === 0x45 && buffer[10] === 0x42 && buffer[11] === 0x50
  ) {
    return { mime: 'image/webp', ext: 'webp' };
  }
  // HEIC/HEIF: ftyp at offset 4
  const ftyp = buffer.slice(4, 8).toString('ascii');
  if (ftyp === 'ftyp') {
    const brand = buffer.slice(8, 12).toString('ascii');
    if (['heic', 'heix', 'hevc', 'hevx', 'mif1', 'msf1'].includes(brand)) {
      return { mime: 'image/heic', ext: 'heic' };
    }
  }

  throw new ApiError(400, 'Conteúdo do arquivo não é uma imagem válida (JPEG, PNG, WEBP ou HEIC).');
}

function sanitizeCommentText(text) {
  if (!text || typeof text !== 'string') return '';
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
    .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '')
    .trim();
}

function sanitizeAuditMetadata(metadata) {
  if (!metadata || typeof metadata !== 'object') return metadata;
  const safe = { ...metadata };
  if (safe.changes && Array.isArray(safe.changes)) {
    safe.changes = safe.changes.filter((k) => !SENSITIVE_AUDIT_FIELDS.includes(k));
  }
  for (const key of SENSITIVE_AUDIT_FIELDS) {
    delete safe[key];
    delete safe[`old_${key}`];
    delete safe[`new_${key}`];
  }
  return safe;
}

function getInviteExpiresAt() {
  const d = new Date();
  d.setDate(d.getDate() + INVITE_TTL_DAYS);
  return d;
}

function getExpiresAtForPointType(type) {
  const d = new Date();
  if (type === 'ocorrencia_recente') {
    d.setDate(d.getDate() + 7);
    return d;
  }
  if (type === 'suspeito') {
    d.setDate(d.getDate() + 30);
    return d;
  }
  if (type === 'local_interesse') {
    d.setDate(d.getDate() + 90);
    return d;
  }
  return null;
}

module.exports = {
  MAX_GROUP_MEMBERS,
  INVITE_TTL_DAYS,
  REPORT_RATE_LIMIT_HOURS,
  REPORT_RATE_LIMIT_MAX,
  normalizeEmail,
  validateBrazilCoordinates,
  validateImageMagicBytes,
  sanitizeCommentText,
  sanitizeAuditMetadata,
  getInviteExpiresAt,
  getExpiresAtForPointType,
};
