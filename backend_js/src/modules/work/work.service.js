// /src/modules/work/work.service.js

const workRepository = require('./work.repository');
const salaryCalculator = require('./salary-calculator');
const salaryService = require('./salary.service');
const ApiError = require('../../core/utils/ApiError');
const { DateTime } = require('luxon');

/**
 * Converte valor DATE do MySQL para 'YYYY-MM-DD'.
 * mysql2 retorna DATE como Date em UTC meia-noite — getUTC* evita deslocamento de 1 dia.
 */
function formatDateOnly(value) {
  if (!value) return null;
  if (typeof value === 'string') {
    if (/^\d{4}-\d{2}-\d{2}$/.test(value)) return value;
    return value.split('T')[0].split(' ')[0];
  }
  if (value instanceof Date) {
    const y = value.getUTCFullYear();
    const m = String(value.getUTCMonth() + 1).padStart(2, '0');
    const d = String(value.getUTCDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }
  return null;
}

/**
 * Normaliza entrada de data para YYYY-MM-DD.
 * Joi isoDate() converte "2025-06-25" em "2025-06-25T00:00:00.000Z";
 * Luxon toISODate() no fuso BR (UTC-3) vira "2025-06-24" — extrair antes de "T" evita isso.
 */
function normalizeInputDate(value) {
  const formatted = formatDateOnly(value);
  if (formatted && /^\d{4}-\d{2}-\d{2}$/.test(formatted)) {
    return formatted;
  }
  return null;
}

class WorkService {
  // Busca dias de um mês
  async getMonthDays(policialId, month, year) {
    const days = await workRepository.findDaysByMonth(policialId, month, year);
    
    // Processa intervalos JSON e formata data para YYYY-MM-DD (sem timezone)
    return days.map(day => {
      // Formata data para YYYY-MM-DD (sem timezone) para evitar deslocamento no frontend
      const formatted = formatDateOnly(day.data);
      if (formatted) {
        day.data = formatted;
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
    const dateOnly = normalizeInputDate(data);
    if (!dateOnly) {
      throw new ApiError(400, 'Data inválida.');
    }
    const [y, m, d] = dateOnly.split('-').map(Number);
    const dateObj = DateTime.fromObject({ year: y, month: m, day: d });

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
    const isAbatimento =
      dayData.tipo === 'abatimento' ||
      dayData.tipo === 'atestado' ||
      dayData.flag_abatimento === true ||
      dayData.flag_abatimento === 1;

    if (etapas === undefined || etapas === null) {
      const etapaRule = dayData.etapa_rule_override || 'per_6h';
      etapas = isAbatimento ? 0 : salaryCalculator.calcEtapasForDay(totalHours, etapaRule);
    } else if (isAbatimento) {
      etapas = 0;
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

    await this._regenerateSalarySafely(policialId, dateObj.month, dateObj.year);

    return result;
  }

  // Deleta um dia
  async deleteDay(policialId, workDayId) {
    const day = await workRepository.findDayById(workDayId, policialId);
    if (!day) {
      throw new ApiError(404, 'Dia não encontrado.');
    }

    // Extrai mês e ano antes de deletar
    const dateOnly = formatDateOnly(day.data);
    const dateObj = dateOnly
      ? DateTime.fromISO(dateOnly)
      : DateTime.fromISO(day.data);
    const month = dateObj.month;
    const year = dateObj.year;

    const result = await workRepository.deleteDay(workDayId, policialId);

    await this._regenerateSalarySafely(policialId, month, year);

    return result;
  }

  async _regenerateSalarySafely(policialId, month, year) {
    try {
      await salaryService.generateMonth(policialId, month, year);
    } catch (error) {
      console.error(
        `[WorkService] Falha ao recalcular salário ${month}/${year} para policial ${policialId}:`,
        error.message
      );
    }
  }

  // Aplica preset em um ou vários dias
  async applyPresetToDays(policialId, dates, presetId, presetData) {
    if (!dates || dates.length === 0) {
      throw new ApiError(400, 'Nenhuma data fornecida.');
    }

    const settings = await salaryService.getSettings(policialId);
    const totalHours = parseFloat(presetData.duracao) || 0;
    const etapaRule =
      presetData.etapa_rule_override || settings.etapa_rule || 'per_6h';
    const isAbatimento =
      presetData.tipo === 'abatimento' ||
      presetData.tipo === 'atestado' ||
      presetData.flag_abatimento === true ||
      presetData.flag_abatimento === 1;
    const etapas = isAbatimento
      ? 0
      : salaryCalculator.calcEtapasForDay(totalHours, etapaRule);

    const normalizedPresetData = {
      ...presetData,
      duracao: totalHours,
      etapas,
      flag_abatimento:
        presetData.flag_abatimento === true || presetData.flag_abatimento === 1,
    };

    // Valida e formata datas para YYYY-MM-DD
    const validDates = [];
    const monthsToUpdate = new Set();

    for (const date of dates) {
      const dateOnly = normalizeInputDate(date);
      if (dateOnly) {
        validDates.push(dateOnly);
        const [year, month] = dateOnly.split('-').map(Number);
        monthsToUpdate.add(`${year}-${month}`);
      }
    }

    if (validDates.length === 0) {
      throw new ApiError(400, 'Nenhuma data válida fornecida.');
    }

    const result = await workRepository.applyPresetToDays(
      policialId,
      validDates,
      presetId,
      normalizedPresetData
    );

    for (const monthKey of monthsToUpdate) {
      const [year, month] = monthKey.split('-').map(Number);
      await this._regenerateSalarySafely(policialId, month, year);
    }

    return result;
  }

  // Busca estatísticas do mês
  async getMonthStats(policialId, month, year) {
    return await workRepository.getMonthStats(policialId, month, year);
  }
}

module.exports = new WorkService();


