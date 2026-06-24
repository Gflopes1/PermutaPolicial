const cron = require('node-cron');
const matchAlertsService = require('./match-alerts.service');
const logger = require('../../core/utils/logger');

function startMatchAlertsJob() {
  if (process.env.ENABLE_MATCH_ALERTS_JOB === 'false') {
    return;
  }

  // 08:00 e 20:00 todos os dias
  cron.schedule('0 8,20 * * *', async () => {
    try {
      const result = await matchAlertsService.runScheduledScan();
      logger.log('[match-alerts] Varredura concluída:', result);
    } catch (error) {
      console.error('[match-alerts] Erro na varredura agendada:', error.message);
    }
  });

  logger.log('[match-alerts] Job agendado (08:00 e 20:00)');
}

module.exports = { startMatchAlertsJob };
