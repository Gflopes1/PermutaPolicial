// Cache e snapshot do grafo (motor experimental isolado)

const zlib = require('zlib');
const { promisify } = require('util');
const db = require('../../config/db');

const gunzip = promisify(zlib.gunzip);

/*
  Migration (executar manualmente em produção):
  ALTER TABLE permutas_inteligentes_graph_snapshot
    MODIFY payload MEDIUMBLOB NOT NULL;
*/

let schemaEnsured = false;

const GRAPH_TTL_HOURS = Number(process.env.PI_GRAPH_TTL_HOURS || 2);
const USER_CACHE_TTL_HOURS = Number(process.env.PI_USER_CACHE_TTL_HOURS || 1);

async function ensureSchema() {
  if (schemaEnsured) return;

  await db.execute(`
    CREATE TABLE IF NOT EXISTS permutas_inteligentes_graph_snapshot (
      id TINYINT UNSIGNED NOT NULL PRIMARY KEY DEFAULT 1,
      payload LONGTEXT NOT NULL,
      node_count INT UNSIGNED NOT NULL DEFAULT 0,
      edge_count INT UNSIGNED NOT NULL DEFAULT 0,
      computed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      expires_at TIMESTAMP NOT NULL,
      CONSTRAINT chk_pi_single_snapshot CHECK (id = 1)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await db.execute(`
    CREATE TABLE IF NOT EXISTS permutas_inteligentes_cache (
      id INT AUTO_INCREMENT PRIMARY KEY,
      policial_id INT NOT NULL,
      payload LONGTEXT NOT NULL,
      match_count INT UNSIGNED NOT NULL DEFAULT 0,
      computed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      expires_at TIMESTAMP NOT NULL,
      UNIQUE KEY uk_pi_cache_policial (policial_id),
      INDEX idx_pi_cache_expires (expires_at),
      CONSTRAINT fk_pi_cache_policial
        FOREIGN KEY (policial_id) REFERENCES policiais(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  schemaEnsured = true;
}

function hoursFromNow(hours) {
  return new Date(Date.now() + hours * 60 * 60 * 1000);
}

function serializeAdjacency(adjacency) {
  return [...adjacency.entries()].map(([fromId, edges]) => [fromId, edges]);
}

function deserializeAdjacency(entries) {
  if (!entries || !Array.isArray(entries)) return null;
  return new Map(entries.map(([fromId, edges]) => [fromId, edges]));
}

function isGzipPayload(raw) {
  if (Buffer.isBuffer(raw)) {
    return raw.length > 0 && raw[0] === 0x1f;
  }
  if (typeof raw === 'string' && raw.length > 0) {
    return raw.charCodeAt(0) === 0x1f;
  }
  return false;
}

function payloadToBuffer(raw) {
  if (Buffer.isBuffer(raw)) return raw;
  return Buffer.from(raw, typeof raw === 'string' ? 'utf8' : undefined);
}

function parseSnapshotPayload(jsonStr) {
  const parsed = JSON.parse(jsonStr);
  if (Array.isArray(parsed)) {
    return { nodes: parsed, adjacency: null };
  }
  return {
    nodes: parsed.nodes || [],
    adjacency: deserializeAdjacency(parsed.adjacency),
  };
}

function decodeSnapshotPayloadAsync(raw) {
  return new Promise((resolve, reject) => {
    setImmediate(async () => {
      try {
        const buf = payloadToBuffer(raw);
        let jsonStr;
        if (isGzipPayload(buf)) {
          const decompressed = await gunzip(buf);
          jsonStr = decompressed.toString('utf8');
        } else {
          jsonStr = buf.toString('utf8');
        }
        resolve(parseSnapshotPayload(jsonStr));
      } catch (error) {
        reject(error);
      }
    });
  });
}

async function getGraphSnapshot() {
  await ensureSchema();
  const [rows] = await db.execute(
    `SELECT payload, node_count, edge_count, computed_at, expires_at
     FROM permutas_inteligentes_graph_snapshot
     WHERE id = 1 AND expires_at > NOW()
     LIMIT 1`
  );

  if (rows.length === 0) return null;

  const row = rows[0];
  const { nodes, adjacency } = await decodeSnapshotPayloadAsync(row.payload);
  return {
    nodes,
    adjacency,
    node_count: row.node_count,
    edge_count: row.edge_count,
    computed_at: row.computed_at,
    expires_at: row.expires_at,
  };
}

async function saveGraphSnapshot(nodes, edgeCount = 0, adjacency = null) {
  await ensureSchema();
  const expiresAt = hoursFromNow(GRAPH_TTL_HOURS);
  const payload = zlib.gzipSync(
    JSON.stringify({
      nodes,
      adjacency: adjacency ? serializeAdjacency(adjacency) : null,
    })
  );

  await db.execute(
    `
    INSERT INTO permutas_inteligentes_graph_snapshot
      (id, payload, node_count, edge_count, computed_at, expires_at)
    VALUES (1, ?, ?, ?, NOW(), ?)
    ON DUPLICATE KEY UPDATE
      payload = VALUES(payload),
      node_count = VALUES(node_count),
      edge_count = VALUES(edge_count),
      computed_at = NOW(),
      expires_at = VALUES(expires_at)
  `,
    [payload, nodes.length, edgeCount, expiresAt]
  );

  return { expires_at: expiresAt, node_count: nodes.length };
}

async function getUserCache(policialId) {
  await ensureSchema();
  const [rows] = await db.execute(
    `SELECT payload, match_count, computed_at, expires_at
     FROM permutas_inteligentes_cache
     WHERE policial_id = ? AND expires_at > NOW()
     LIMIT 1`,
    [policialId]
  );

  if (rows.length === 0) return null;

  const row = rows[0];
  return {
    result: JSON.parse(row.payload),
    match_count: row.match_count,
    computed_at: row.computed_at,
    expires_at: row.expires_at,
  };
}

async function saveUserCache(policialId, result) {
  await ensureSchema();
  const expiresAt = hoursFromNow(USER_CACHE_TTL_HOURS);
  const matchCount =
    (result.diretas?.length || 0) +
    (result.proximas?.length || 0) +
    (result.interessados?.length || 0) +
    (result.triangulares?.length || 0) +
    (result.ciclos_n?.length || 0);

  const payload = JSON.stringify(result);

  await db.execute(
    `
    INSERT INTO permutas_inteligentes_cache
      (policial_id, payload, match_count, computed_at, expires_at)
    VALUES (?, ?, ?, NOW(), ?)
    ON DUPLICATE KEY UPDATE
      payload = VALUES(payload),
      match_count = VALUES(match_count),
      computed_at = NOW(),
      expires_at = VALUES(expires_at)
  `,
    [policialId, payload, matchCount, expiresAt]
  );

  return { match_count: matchCount, expires_at: expiresAt };
}

async function invalidateUserCache(policialId) {
  await ensureSchema();
  await db.execute('DELETE FROM permutas_inteligentes_cache WHERE policial_id = ?', [
    policialId,
  ]);
}

async function invalidateAllUserCaches() {
  await ensureSchema();
  await db.execute('DELETE FROM permutas_inteligentes_cache');
}

async function invalidateGraphSnapshot() {
  await ensureSchema();
  await db.execute('DELETE FROM permutas_inteligentes_graph_snapshot WHERE id = 1');
}

async function purgeExpired() {
  await ensureSchema();
  await db.execute('DELETE FROM permutas_inteligentes_cache WHERE expires_at <= NOW()');
  await db.execute(
    'DELETE FROM permutas_inteligentes_graph_snapshot WHERE expires_at <= NOW()'
  );
}

module.exports = {
  GRAPH_TTL_HOURS,
  USER_CACHE_TTL_HOURS,
  ensureSchema,
  getGraphSnapshot,
  saveGraphSnapshot,
  getUserCache,
  saveUserCache,
  invalidateUserCache,
  invalidateAllUserCaches,
  invalidateGraphSnapshot,
  purgeExpired,
};
