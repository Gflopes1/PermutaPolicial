require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const { encryptField } = require('../src/core/utils/field-crypto.utils');
const { isSensitivePointType } = require('../src/modules/mapa-tatico/mapa-tatico-crypto.utils');
const db = require('../src/config/db');
const logger = require('../src/core/utils/logger');

const BATCH_SIZE = 100;

async function migrateSensitiveMapPoints() {
  let lastId = 0;
  let total = 0;

  while (true) {
    const [rows] = await db.execute(
      `SELECT id, type, title, description, address
       FROM map_points
       WHERE id > ? AND type IN ('suspeito', 'ocorrencia_recente')
       ORDER BY id ASC
       LIMIT ${BATCH_SIZE}`,
      [lastId]
    );

    if (rows.length === 0) break;

    for (const row of rows) {
      if (!isSensitivePointType(row.type)) continue;
      if (String(row.title || '').startsWith('v1:')) continue;

      await db.execute(
        `UPDATE map_points SET title = ?, description = ?, address = ? WHERE id = ?`,
        [
          encryptField(row.title),
          row.description != null ? encryptField(row.description) : null,
          row.address != null ? encryptField(row.address) : null,
          row.id,
        ]
      );
      total += 1;
      lastId = row.id;
    }

    logger.info('[mapa-tatico] Migração de criptografia — lote concluído', {
      migrated_total: total,
      last_id: lastId,
    });
  }

  logger.info('[mapa-tatico] Migração de criptografia concluída', { migrated_total: total });
  return total;
}

if (require.main === module) {
  migrateSensitiveMapPoints()
    .then((count) => {
      console.log(`Migrados ${count} pontos sensíveis.`);
      process.exit(0);
    })
    .catch((err) => {
      console.error(err.message);
      process.exit(1);
    });
}

module.exports = { migrateSensitiveMapPoints };
