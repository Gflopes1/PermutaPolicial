// Encrypt/decrypt de campos sensíveis do mapa tático (Fase 6)

const { encryptField, decryptField } = require('../../core/utils/field-crypto.utils');

const SENSITIVE_POINT_TYPES = ['suspeito', 'ocorrencia_recente'];
const SENSITIVE_POINT_FIELDS = ['title', 'description', 'address'];

const SUSPECT_PROFILE_FIELDS = [
  'apelido',
  'caracteristicas_fisicas',
  'altura_cm',
  'compleicao',
  'tatuagens_marcas',
  'veiculos_associados',
  'modus_operandi',
  'nivel_periculosidade',
  'orientacoes_abordagem',
  'bo_rai_numero',
  'fundamentacao',
];

const OCCURRENCE_LOG_FIELDS = ['entry_type', 'narrative', 'status', 'occurred_at'];

function isSensitivePointType(type) {
  return SENSITIVE_POINT_TYPES.includes(type);
}

function encryptPointFields(data, type) {
  if (!isSensitivePointType(type)) return data;
  const out = { ...data };
  for (const field of SENSITIVE_POINT_FIELDS) {
    if (out[field] !== undefined && out[field] !== null) {
      out[field] = encryptField(out[field]);
    }
  }
  return out;
}

function decryptPointRow(row) {
  if (!row || !isSensitivePointType(row.type)) return row;
  const out = { ...row };
  for (const field of SENSITIVE_POINT_FIELDS) {
    if (out[field] != null) {
      try {
        out[field] = decryptField(out[field]);
      } catch (_) {
        // Dado legado em texto plano permanece até migração manual.
      }
    }
  }
  return out;
}

function encryptSuspectProfileFields(data) {
  const out = { ...data };
  for (const field of SUSPECT_PROFILE_FIELDS) {
    if (out[field] !== undefined && out[field] !== null && out[field] !== '') {
      out[field] = encryptField(String(out[field]));
    }
  }
  return out;
}

function decryptSuspectProfileRow(row) {
  if (!row) return row;
  const out = { ...row };
  for (const field of SUSPECT_PROFILE_FIELDS) {
    if (out[field] != null) {
      try {
        out[field] = decryptField(out[field]);
      } catch (_) {
        // Dado legado em texto plano permanece até migração manual.
      }
    }
  }
  if (out.altura_cm != null) {
    const parsed = parseInt(out.altura_cm, 10);
    out.altura_cm = Number.isNaN(parsed) ? null : parsed;
  }
  return out;
}

function encryptOccurrenceLogFields(data) {
  const out = { ...data };
  for (const field of OCCURRENCE_LOG_FIELDS) {
    if (out[field] === undefined || out[field] === null) continue;
    const value = out[field] instanceof Date ? out[field].toISOString() : String(out[field]);
    out[field] = encryptField(value);
  }
  return out;
}

function decryptOccurrenceLogRow(row) {
  if (!row) return row;
  const out = { ...row };
  for (const field of OCCURRENCE_LOG_FIELDS) {
    if (out[field] != null) {
      try {
        out[field] = decryptField(out[field]);
      } catch (_) {
        // Dado legado em texto plano permanece até migração manual.
      }
    }
  }
  return out;
}

module.exports = {
  isSensitivePointType,
  encryptPointFields,
  decryptPointRow,
  encryptSuspectProfileFields,
  decryptSuspectProfileRow,
  encryptOccurrenceLogFields,
  decryptOccurrenceLogRow,
  SENSITIVE_POINT_TYPES,
  SUSPECT_PROFILE_FIELDS,
};
