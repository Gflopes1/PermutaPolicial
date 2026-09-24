// /src/modules/work/salary.job.js

const cron = require('node-cron');
const salaryService = require('./salary.service');
const salaryRepository = require('./salary.repository');
const db = require('../../config/db');
const { DateTime } = require('luxon');
const logger = require('../../core/utils/logger');

/**
 * Job que processa salários automaticamente no dia 20 de cada mês
 * (ou no dia configurado pelo usuário para pagamento do VA)
 */
async function processMonthlySalaries() {
  logger.log('🔄 Iniciando processamento automático de salários...');
  
  const timezone = 'America/Sao_Paulo';
  const now = DateTime.now().setZone(timezone);
  const currentMonth = now.month;
  const currentYear = now.year;
  const currentDay = now.day;

  try {
    // Busca todos os usuários que têm configurações de salário
    const [users] = await db.execute(
      'SELECT DISTINCT policial_id FROM salary_settings'
    );

    logger.log(`📊 Encontrados ${users.length} usuários para processar.`);

    for (const user of users) {
      const policialId = user.policial_id;
      
      try {
        // Busca configurações do usuário
        const settings = await salaryRepository.findSettingsByPolicialId(policialId);
        if (!settings) continue;

        // Verifica se é o dia de pagamento do VA (ou dia 20 por padrão)
        const diaPagamento = settings.dia_pagamento_va || 20;
        
        // Processa apenas se for o dia de pagamento
        if (currentDay === diaPagamento) {
          // Processa o mês anterior (salário do mês passado)
          const previousMonth = currentMonth === 1 ? 12 : currentMonth - 1;
          const previousYear = currentMonth === 1 ? currentYear - 1 : currentYear;

          // Verifica se já foi processado
          const existing = await salaryRepository.findResultByMonth(
            policialId,
            previousMonth,
            previousYear
          );

          if (!existing || existing.status !== 'PROCESSADO') {
            logger.log(`💰 Processando salário de ${previousMonth}/${previousYear} para usuário ${policialId}`);
            await salaryService.generateMonth(policialId, previousMonth, previousYear);
            logger.log(`✅ Salário processado com sucesso para usuário ${policialId}`);
          } else {
            logger.log(`⏭️  Salário de ${previousMonth}/${previousYear} já foi processado para usuário ${policialId}`);
          }
        }
      } catch (error) {
        console.error(`❌ Erro ao processar salário do usuário ${policialId}:`, error.message);
        // Continua processando outros usuários mesmo se um falhar
      }
    }

    logger.log('✅ Processamento automático de salários concluído.');
  } catch (error) {
    console.error('💥 Erro no job de processamento de salários:', error);
  }
}

/**
 * Inicia o job cron
 * Executa diariamente às 02:00 (horário de Brasília)
 */
function startSalaryJob() {
  // Executa diariamente às 02:00 (horário de Brasília)
  cron.schedule('0 2 * * *', async () => {
    await processMonthlySalaries();
  }, {
    scheduled: true,
    timezone: 'America/Sao_Paulo'
  });

  logger.log('✅ Job de processamento de salários iniciado (executa diariamente às 02:00).');
}

module.exports = {
  processMonthlySalaries,
  startSalaryJob
};


