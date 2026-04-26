// /src/modules/work/work.service.js

const workRepository = require('./work.repository');
const salaryCalculator = require('./salary-calculator');
const salaryService = require('./salary.service');
const ApiError = require('../../core/utils/ApiError');
const { DateTime } = require('luxon');

class WorkService {
  // Busca dias de um mês
  async getMonthDays(policialId, month, year) {
    const days = await workRepository.findDaysByMonth(policialId, month, year);
    
    // Processa intervalos JSON e formata data para YYYY-MM-DD (sem timezone)
    return days.map(day => {
      // Formata data para YYYY-MM-DD (sem timezone) para evitar deslocamento no frontend
      if (day.data) {
        // Se for um objeto Date do MySQL, converte para string YYYY-MM-DD
        if (day.data instanceof Date) {
          const year = day.data.getFullYear();
          const month = String(day.data.getMonth() + 1).padStart(2, '0');
          const dayNum = String(day.data.getDate()).padStart(2, '0');
          day.data = `${year}-${month}-${dayNum}`;
        } else if (typeof day.data === 'string') {
          // Se já for string, extrai apenas a parte da data (YYYY-MM-DD)
          if (day.data.includes('T')) {
            day.data = day.data.split('T')[0];
          } else if (day.data.includes(' ')) {
            day.data = day.data.split(' ')[0];
          }
        }
      }
      
      if (day.intervals_json) {
        try {
          day.intervals = JSON.parse(`[${day.intervals_json}]`);
        } catch (e) {
          day.intervals = [];
        }
      } else {
        day.intervals = [];
      }
      delete day.intervals_json;
      return day;
    });
  }

  // Cria ou atualiza um dia
  async upsertDay(policialId, data, dayData, intervals = []) {
    // Valida data
    const dateObj = DateTime.fromISO(data);
    if (!dateObj.isValid) {
      throw new ApiError(400, 'Data inválida.');
    }

    // Trunca data para formato YYYY-MM-DD (MySQL espera apenas a data, não datetime)
    const dateOnly = dateObj.toISODate(); // Retorna 'YYYY-MM-DD'

    // SIMPLIFICADO: Usa total_hours diretamente (intervalos são opcionais e não necessários)
    // Se total_hours não foi fornecido, tenta calcular a partir de intervalos (compatibilidade)
    let totalHours = dayData.total_hours;
    let etapas = dayData.etapas;

    // Se não tem total_hours mas tem intervalos, calcula (compatibilidade retroativa)
    if ((totalHours === undefined || totalHours === null) && intervals && intervals.length > 0) {
      totalHours = intervals.reduce((sum, interval) => {
        const hours = salaryCalculator.calcIntervalHours(
          interval.start_time,
          interval.end_time
        );
        return sum + hours;
      }, 0);
    }

    // Se ainda não tem total_hours, usa 0 (preset será aplicado no repository se necessário)
    if (totalHours === undefined || totalHours === null) {
      totalHours = 0;
    }

    // Calcula etapas se não foi fornecido
    if (etapas === undefined || etapas === null) {
      const etapaRule = dayData.etapa_rule_override || 'per_6h';
      etapas = salaryCalculator.calcEtapasForDay(totalHours, etapaRule);
    }

    const workDayData = {
      ...dayData,
      total_hours: totalHours,
      etapas: etapas
    };

    // Processa intervalos apenas se fornecidos (opcional, para compatibilidade)
    const processedIntervals = (intervals && intervals.length > 0) ? intervals.map(interval => {
      const start = new Date(interval.start_time);
      const end = new Date(interval.end_time);
      const duracaoMinutos = Math.round((end - start) / (1000 * 60));

      return {
        start_time: start.toISOString().slice(0, 19).replace('T', ' '),
        end_time: end.toISOString().slice(0, 19).replace('T', ' '),
        duracao_minutos: duracaoMinutos
      };
    }) : [];

    const result = await workRepository.upsertDay(
      policialId,
      dateOnly, // Usa data truncada
      workDayData,
      processedIntervals
    );

    // Persistência automática: gera resultado do mês após salvar
    const month = dateObj.month;
    const year = dateObj.year;
    await salaryService.generateMonth(policialId, month, year);

    return result;
  }

  // Deleta um dia
  async deleteDay(policialId, workDayId) {
    const day = await workRepository.findDayById(workDayId, policialId);
    if (!day) {
      throw new ApiError(404, 'Dia não encontrado.');
    }

    // Extrai mês e ano antes de deletar
    const dateObj = DateTime.fromISO(day.data);
    const month = dateObj.month;
    const year = dateObj.year;

    const result = await workRepository.deleteDay(workDayId, policialId);

    // Persistência automática: gera resultado do mês após deletar
    await salaryService.generateMonth(policialId, month, year);

    return result;
  }

  // Aplica preset em massa
  async applyPresetToDays(policialId, dates, presetId, presetData) {
    if (!dates || dates.length === 0) {
      throw new ApiError(400, 'Nenhuma data fornecida.');
    }

    // Valida e formata datas para YYYY-MM-DD
    // IMPORTANTE: Trata datas como strings YYYY-MM-DD diretamente, sem conversão de timezone
    const validDates = [];
    const monthsToUpdate = new Set(); // Para rastrear quais meses precisam ser atualizados

    for (const date of dates) {
      // Se já está no formato YYYY-MM-DD, usa diretamente
      if (typeof date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(date)) {
        validDates.push(date);
        // Extrai mês e ano da string
        const [year, month] = date.split('-').map(Number);
        monthsToUpdate.add(`${year}-${month}`);
      } else {
        // Se não está no formato correto, tenta parsear
        const dateObj = DateTime.fromISO(date);
        if (dateObj.isValid) {
          // Usa toISODate() que retorna apenas a data sem timezone
          const dateOnly = dateObj.toISODate(); // 'YYYY-MM-DD'
          validDates.push(dateOnly);
          monthsToUpdate.add(`${dateObj.year}-${dateObj.month}`);
        }
      }
    }

    if (validDates.length === 0) {
      throw new ApiError(400, 'Nenhuma data válida fornecida.');
    }

    const result = await workRepository.applyPresetToDays(
      policialId,
      validDates,
      presetId,
      presetData
    );

    // Persistência automática: gera resultado do mês para cada mês afetado
    for (const monthKey of monthsToUpdate) {
      const [year, month] = monthKey.split('-').map(Number);
      await salaryService.generateMonth(policialId, month, year);
    }

    return result;
  }

  // Busca estatísticas do mês
  async getMonthStats(policialId, month, year) {
    return await workRepository.getMonthStats(policialId, month, year);
  }
}

module.exports = new WorkService();


