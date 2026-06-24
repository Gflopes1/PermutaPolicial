// Cache de snapshot do mapa de permutas — padrão similar a permutas-inteligentes.cache.repository.js

const db = require('../../config/db');

let schemaEnsured = false;

/** TTL padrão: 12 min (entre 10–15 min conforme especificação) */
const MAPA_CACHE_TTL_MINUTES = Number(process.env.MAPA_CACHE_TTL_MINUTES || 12);

async function ensureSchema() {
  if (schemaEnsured) return;

  await db.execute(`
    CREATE TABLE IF NOT EXISTS mapa_snapshot (
      cache_key VARCHAR(120) NOT NULL PRIMARY KEY,
      payload LONGTEXT NOT NULL,
      computed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      expires_at TIMESTAMP NOT NULL,
      INDEX idx_mapa_snapshot_expires (expires_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  schemaEnsured = true;
}

function buildCacheKey(filters) {
  const tipo = filters.tipo || 'saindo';
  const estado = filters.estado_id != null ? String(filters.estado_id) : '';
  const forca = filters.forca_id != null ? String(filters.forca_id) : '';
  return `${tipo}|${estado}|${forca}`;
}

function minutesFromNow(minutes) {
  return new Date(Date.now() + minutes * 60 * 1000);
}

async function getSnapshot(filters) {
  await ensureSchema();
  const cacheKey = buildCacheKey(filters);

  const [rows] = await db.execute(
    `SELECT payload, computed_at, expires_at
     FROM mapa_snapshot
     WHERE cache_key = ? AND expires_at > NOW()
     LIMIT 1`,
    [cacheKey]
  );

  if (rows.length === 0) return null;

  const row = rows[0];
  return {
    cache_key: cacheKey,
    data: JSON.parse(row.payload),
    computed_at: row.computed_at,
    expires_at: row.expires_at,
    hit: true,
  };
}

async function saveSnapshot(filters, data) {
  await ensureSchema();
  const cacheKey = buildCacheKey(filters);
  const expiresAt = minutesFromNow(MAPA_CACHE_TTL_MINUTES);
  const payload = JSON.stringify(data);

  await db.execute(
    `INSERT INTO mapa_snapshot (cache_key, payload, computed_at, expires_at)
     VALUES (?, ?, NOW(), ?)
     ON DUPLICATE KEY UPDATE
       payload = VALUES(payload),
       computed_at = NOW(),
       expires_at = VALUES(expires_at)`,
    [cacheKey, payload, expiresAt]
  );

  return { cache_key: cacheKey, expires_at: expiresAt };
}

async function purgeExpired() {
  await ensureSchema();
  await db.execute('DELETE FROM mapa_snapshot WHERE expires_at <= NOW()');
}

module.exports = {
  MAPA_CACHE_TTL_MINUTES,
  buildCacheKey,
  getSnapshot,
  saveSnapshot,
  purgeExpired,
};
