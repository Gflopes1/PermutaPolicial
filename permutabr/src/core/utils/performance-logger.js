// Buffer circular de métricas de performance (memória) — exposto no admin.
// Módulos registram eventos estruturados; não persiste em disco por padrão.

const MAX_ENTRIES = 500;
const logger = require('../../core/utils/logger');

/** @type {Array<{ id: number, module: string, event: string, data: object, at: string }>} */
const entries = [];
let nextId = 1;

/**
 * Registra métrica estruturada e espelha no console para observabilidade.
 * @param {string} module - Ex: 'PI', 'MAPA'
 * @param {string} event - Ex: 'graph_build', 'map_data'
 * @param {Record<string, unknown>} data
 */
function record(module, event, data = {}) {
  const row = {
    id: nextId++,
    module,
    event,
    data,
    at: new Date().toISOString(),
  };

  entries.unshift(row);
  if (entries.length > MAX_ENTRIES) {
    entries.length = MAX_ENTRIES;
  }

  logger.log(`[${module}]`, { event, ...data, at: row.at });
}

/**
 * @param {{ limit?: number, module?: string }} [opts]
 */
function getRecent(opts = {}) {
  const limit = Math.min(Math.max(Number(opts.limit) || 100, 1), MAX_ENTRIES);
  const moduleFilter = opts.module ? String(opts.module).toUpperCase() : null;

  let list = entries;
  if (moduleFilter) {
    list = entries.filter((e) => e.module === moduleFilter);
  }

  return list.slice(0, limit);
}

function clear() {
  entries.length = 0;
}

module.exports = {
  record,
  getRecent,
  clear,
  MAX_ENTRIES,
};
