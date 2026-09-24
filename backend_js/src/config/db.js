// /src/config/db.js

const mysql = require('mysql2/promise');
const logger = require('../core/utils/logger');

function parsePort(value, fallback) {
    const parsed = parseInt(value, 10);
    return Number.isFinite(parsed) ? parsed : fallback;
}

function resolvePoolLimit() {
    if (process.env.DB_POOL_SIZE) {
        return parsePort(process.env.DB_POOL_SIZE, 10);
    }
    const maxConnections = parsePort(process.env.MAX_DB_CONNECTIONS, 100);
    const numWorkers =
        parsePort(process.env.WEB_CONCURRENCY, 0) ||
        parsePort(process.env.PASSENGER_MAX_POOL_SIZE, 0) ||
        1;
    return Math.max(2, Math.floor(maxConnections / numWorkers) - 2);
}

const poolConfig = {
    host: process.env.DB_HOST,
    port: parsePort(process.env.DB_PORT, 3306),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: resolvePoolLimit(),
    queueLimit: 0,
};

const dbHost = (process.env.DB_HOST || '').toLowerCase();
if (dbHost && dbHost !== 'localhost' && dbHost !== '127.0.0.1') {
    poolConfig.ssl = { rejectUnauthorized: true };
}

const pool = mysql.createPool(poolConfig);

const REQUIRED_TABLES = ['daily_usage_limits'];

async function verifyRequiredTables() {
    for (const tableName of REQUIRED_TABLES) {
        const [rows] = await pool.execute(
            `SELECT COUNT(*) AS c FROM information_schema.tables
             WHERE table_schema = DATABASE() AND table_name = ?`,
            [tableName]
        );
        if (rows[0].c === 0) {
            throw new Error(
                `Tabela obrigatória "${tableName}" não existe. Execute a migration correspondente em database/migrations/.`
            );
        }
    }
    logger.debug('Tabelas obrigatórias verificadas', { tables: REQUIRED_TABLES });
}

module.exports = pool;
module.exports.verifyRequiredTables = verifyRequiredTables;
