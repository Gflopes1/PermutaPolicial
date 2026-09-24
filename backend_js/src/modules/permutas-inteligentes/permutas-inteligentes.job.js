const cron = require('node-cron');
const permutasInteligentesService = require('./permutas-inteligentes.service');
const logger = require('../../core/utils/logger');

function startPermutasInteligentesJob() {
  if (process.env.ENABLE_PERMUTAS_INTELIGENTES_JOB === 'false') {
    return;
  }

  // A cada 2 horas: rebuild do grafo + cache dos usuários ativos
  cron.schedule('0 */2 * * *', async () => {
    try {
      const result = await permutasInteligentesService.runCacheRefreshJob({
        rebuildGraph: true,
        userLimit: 0,
      });
      logger.log('[permutas-inteligentes] Job concluído:', result);
    } catch (error) {
      console.error('[permutas-inteligentes] Erro no job:', error.message);
    }
  });

  logger.log('[permutas-inteligentes] Job agendado (a cada 2 horas)');
}

module.exports = { startPermutasInteligentesJob };
