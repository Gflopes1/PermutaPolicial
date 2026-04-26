// /src/modules/work/salary.service.js

const salaryRepository = require('./salary.repository');
const workRepository = require('./work.repository');
const presetsService = require('./presets.service');
const salaryCalculator = require('./salary-calculator');
const ApiError = require('../../core/utils/ApiError');

class SalaryService {
  // Busca configurações de salário
  async getSettings(policialId) {
    let settings = await salaryRepository.findSettingsByPolicialId(policialId);
    
    // Se não existe, cria com defaults
    if (!settings) {
      await salaryRepository.upsertSettings(policialId, {});
      // Cria presets iniciais também
      await presetsService.createInitialPresets(policialId);
      settings = await salaryRepository.findSettingsByPolicialId(policialId);
    }

    return settings;
  }

  // Atualiza configurações de salário
  async updateSettings(policialId, settingsData) {
    // Debug: log dos dados recebidos (antes da validação)
    console.log('[Salary Service] Dados recebidos para updateSettings:', JSON.stringify(settingsData, null, 2));
    
    // Validações
    if (settingsData.previdencia_aliquota !== undefined) {
      if (settingsData.previdencia_aliquota < 0 || settingsData.previdencia_aliquota > 1) {
        throw new ApiError(400, 'Alíquota de previdência deve estar entre 0 e 1.');
      }
    }

    if (settingsData.dia_pagamento_va !== undefined) {
      if (settingsData.dia_pagamento_va < 1 || settingsData.dia_pagamento_va > 31) {
        throw new ApiError(400, 'Dia de pagamento do VA deve estar entre 1 e 31.');
      }
    }

    await salaryRepository.upsertSettings(policialId, settingsData);
    return await this.getSettings(policialId);
  }

  // Preview do cálculo do mês (não salva)
  async previewMonth(policialId, month, year) {
    const settings = await this.getSettings(policialId);
    const workDays = await workRepository.findDaysByMonth(policialId, month, year);

    // Processa workDays para formato esperado pelo calculator
    const processedDays = workDays.map(day => ({
      tipo: day.tipo || 'normal',
      total_hours: parseFloat(day.total_hours) || 0,
      etapas: parseInt(day.etapas) || 0,
      flag_abatimento: day.flag_abatimento || false,
      etapa_rule_override: day.etapa_rule_override || null
    }));

    const result = salaryCalculator.calcSalaryMonth(processedDays, settings, month, year);
    return result;
  }

  // Gera e salva resultado do mês
  async generateMonth(policialId, month, year) {
    const settings = await this.getSettings(policialId);
    const workDays = await workRepository.findDaysByMonth(policialId, month, year);

    // Processa workDays
    const processedDays = workDays.map(day => ({
      tipo: day.tipo || 'normal',
      total_hours: parseFloat(day.total_hours) || 0,
      etapas: parseInt(day.etapas) || 0,
      flag_abatimento: day.flag_abatimento || false,
      etapa_rule_override: day.etapa_rule_override || null
    }));

    const result = salaryCalculator.calcSalaryMonth(processedDays, settings, month, year);
    
    // Salva resultado
    await salaryRepository.upsertResult(policialId, month, year, {
      ...result,
      status: 'PROCESSADO'
    });

    return result;
  }

  // Busca resultado de um mês
  async getResult(policialId, month, year) {
    return await salaryRepository.findResultByMonth(policialId, month, year);
  }

  // Busca todos os resultados
  async getAllResults(policialId, limit = 12) {
    return await salaryRepository.findAllResultsByPolicialId(policialId, limit);
  }
}

module.exports = new SalaryService();


