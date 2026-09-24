  // /src/modules/work/salary-calculator.js

  const { DateTime } = require('luxon');

  /**
   * Calcula o número de etapas para um dia baseado nas horas trabalhadas
   * @param {number} totalHours - Total de horas do dia
   * @param {string} etapaRule - Regra de etapas ('per_6h', 'per_8h', 'fixed_X')
   * @param {number} customValue - Valor customizado (para regras fixed)
   * @returns {number} - Número de etapas (sempre arredondado para baixo)
   */
  function calcEtapasForDay(totalHours, etapaRule = 'per_6h', customValue = null) {
    if (!totalHours || totalHours <= 0) return 0;

    switch (etapaRule) {
      case 'per_6h':
        return Math.floor(totalHours / 6);
      case 'per_8h':
        return Math.floor(totalHours / 8);
      case 'fixed':
        return customValue ? Math.floor(customValue) : 0;
      default:
        // Default: 1 etapa a cada 6 horas
        return Math.floor(totalHours / 6);
    }
  }

  /**
   * Calcula minutos de sobreposição entre dois intervalos
   * @param {Date|string} start1 - Início do intervalo 1
   * @param {Date|string} end1 - Fim do intervalo 1
   * @param {Date|string} start2 - Início do intervalo 2
   * @param {Date|string} end2 - Fim do intervalo 2
   * @returns {number} - Minutos de sobreposição
   */
  function computeOverlapMinutes(start1, end1, start2, end2) {
    const s1 = DateTime.fromJSDate(new Date(start1));
    const e1 = DateTime.fromJSDate(new Date(end1));
    const s2 = DateTime.fromJSDate(new Date(start2));
    const e2 = DateTime.fromJSDate(new Date(end2));

    const overlapStart = s1 > s2 ? s1 : s2;
    const overlapEnd = e1 < e2 ? e1 : e2;

    if (overlapStart >= overlapEnd) {
      return 0;
    }

    return Math.round(overlapEnd.diff(overlapStart, 'minutes').minutes);
  }

  /**
   * Tabela progressiva mensal tradicional (Lei 15.270/2025 — vigência 2026).
   * @param {number} baseCalculo
   * @returns {number}
   */
  function calcIRPFTradicional(baseCalculo) {
    if (baseCalculo <= 2428.80) {
      return 0;
    }
    if (baseCalculo <= 2826.65) {
      return baseCalculo * 0.075 - 182.16;
    }
    if (baseCalculo <= 3751.05) {
      return baseCalculo * 0.15 - 394.16;
    }
    if (baseCalculo <= 4664.68) {
      return baseCalculo * 0.225 - 675.49;
    }
    return baseCalculo * 0.275 - 908.73;
  }

  /**
   * Calcula IRPF mensal conforme regras de 2026 (Lei 15.270/2025).
   *
   * Base de cálculo: (salário_base + horas_extras) − previdência — sem VA, etapas ou outras vantagens.
   *
   * Faixas:
   * - Até R$ 5.000: isento
   * - R$ 5.000,01 a R$ 7.350: tabela tradicional − redutor progressivo
   * - Acima de R$ 7.350: tabela tradicional integral
   * - Acima de R$ 50.000: trava IRPFM (alíquota mínima de 10% sobre a base)
   *
   * @param {number} baseCalculo
   * @returns {number}
   */
  function calcIRPF(baseCalculo) {
    if (baseCalculo <= 0) {
      return 0;
    }

    if (baseCalculo <= 5000) {
      return 0;
    }

    const irpfTradicional = Math.max(0, calcIRPFTradicional(baseCalculo));
    let irpf = irpfTradicional;

    if (baseCalculo <= 7350) {
      const redutor = 978.62 - (0.133145 * baseCalculo);
      const desconto = Math.max(0, Math.min(redutor, irpfTradicional));
      irpf = irpfTradicional - desconto;
    }

    if (baseCalculo > 50000) {
      const irpfmMinimo = baseCalculo * 0.10;
      irpf = Math.max(irpf, irpfmMinimo);
    }

    return Math.max(0, Math.round(irpf * 100) / 100);
  }

  /**
   * Calcula o salário do mês completo
   * @param {Object} params - Parâmetros de cálculo
   * @param {Array} workDays - Array de dias trabalhados
   * @param {Object} settings - Configurações de salário do usuário
   * @param {number} month - Mês (1-12)
   * @param {number} year - Ano
   * @returns {Object} - Resultado do cálculo
   */
  function calcSalaryMonth(workDays, settings, month, year) {
    const timezone = 'America/Sao_Paulo';
    
    // Calcula dias do mês
    const daysInMonth = DateTime.fromObject({ year, month, day: 1 }, { zone: timezone }).daysInMonth;
    let cargaHorariaMes = daysInMonth * (settings.carga_horaria_dia || 5.70);

    // Totais do mês
    let totalHoras = 0;
    let totalEtapas = 0;
    let diasTrabalhados = 0;
    let diasFerias = 0;
    let horasAbatimento = 0;

    // Processa cada dia
    workDays.forEach(day => {
      const dayType = day.tipo || 'normal';
      
      if (dayType === 'ferias') {
        diasFerias++;
        return; // Férias não contam horas/etapas
      }

      if (dayType === 'folga') {
        return; // Folga não conta
      }

      const isAbatimento =
        day.flag_abatimento || dayType === 'abatimento' || dayType === 'atestado';

      if (isAbatimento) {
        const horasAbat =
          day.total_hours && day.total_hours > 0
            ? parseFloat(day.total_hours)
            : settings.abatimento_horas || 5.70;
        horasAbatimento += horasAbat;
        return;
      }

      // Calcula horas do dia
      let horasDia = 0;
      
      if (day.total_hours && day.total_hours > 0) {
        horasDia = parseFloat(day.total_hours);
      }

      // Dia normal sem horas não entra no cálculo
      if (dayType === 'normal' && horasDia <= 0) {
        return;
      }

      // Calcula etapas do dia
      const etapaRule = day.etapa_rule_override || settings.etapa_rule || 'per_6h';
      const etapasDia = calcEtapasForDay(horasDia, etapaRule);

      totalHoras += horasDia;
      totalEtapas += etapasDia;
      diasTrabalhados++;
    });

    cargaHorariaMes = Math.max(0, cargaHorariaMes - horasAbatimento);

    // Calcula horas extras
    const horasExtras = Math.max(0, totalHoras - cargaHorariaMes);

    // Valores monetários
    const valorEtapas = totalEtapas * (settings.etapa_value || 11.00);
    const valorHorasExtras = horasExtras * (settings.valor_hora_extra || 44.00);
    
    // VA: não creditar se houver dias de férias no mês
    const valeAlimentacao = diasFerias > 0 ? 0 : (settings.vale_alimentacao || 426.00);

    // Outras vantagens (ex: substituição)
    const outrasVantagens = settings.outras_vantagens || 0;

    // Salário (sem VA) e total de recebimentos
    const salarioBrutoFolha =
      (settings.salario_base || 0) + valorHorasExtras + outrasVantagens;
    const salarioBruto = salarioBrutoFolha + valorEtapas;
    const totalRecebimentos = salarioBruto + valeAlimentacao;

    // Previdência: salário base + horas extras (VA, etapas e outras vantagens ficam de fora)
    const basePrevidencia = (settings.salario_base || 0) + valorHorasExtras;
    const descontoPrevidencia = basePrevidencia * (settings.previdencia_aliquota || 0.14);

    // IRPF: apenas (salário_base + horas_extras) − previdência
    const baseIRPF = Math.max(0, basePrevidencia - descontoPrevidencia);
    const descontoIRPF = calcIRPF(baseIRPF);

    const descontoConsignados = settings.desconto_consignados || 0;
    const outrosDescontos = settings.outros_descontos || 0;

    const salarioLiquidoFolha =
      salarioBrutoFolha - descontoPrevidencia - descontoIRPF - descontoConsignados - outrosDescontos;
    const vaMaisEtapas = valeAlimentacao + valorEtapas;
    const salarioLiquido = salarioLiquidoFolha + vaMaisEtapas;

    return {
      total_horas: Math.round(totalHoras * 100) / 100,
      horas_abatimento: Math.round(horasAbatimento * 100) / 100,
      carga_horaria_mes: Math.round(cargaHorariaMes * 100) / 100,
      horas_extras: Math.round(horasExtras * 100) / 100,
      total_etapas: totalEtapas,
      valor_etapas: Math.round(valorEtapas * 100) / 100,
      vale_alimentacao: Math.round(valeAlimentacao * 100) / 100,
      outras_vantagens: Math.round(outrasVantagens * 100) / 100,
      valor_horas_extras: Math.round(valorHorasExtras * 100) / 100,
      salario_base: Math.round((settings.salario_base || 0) * 100) / 100,
      salario_bruto: Math.round(salarioBruto * 100) / 100,
      total_recebimentos: Math.round(totalRecebimentos * 100) / 100,
      base_irpf: Math.round(baseIRPF * 100) / 100,
      desconto_previdencia: Math.round(descontoPrevidencia * 100) / 100,
      desconto_irpf: Math.round(descontoIRPF * 100) / 100,
      desconto_consignados: Math.round(descontoConsignados * 100) / 100,
      outros_descontos: Math.round(outrosDescontos * 100) / 100,
      salario_liquido: Math.round(salarioLiquido * 100) / 100,
      salario_liquido_folha: Math.round(salarioLiquidoFolha * 100) / 100,
      va_mais_etapas: Math.round(vaMaisEtapas * 100) / 100,
      dias_trabalhados: diasTrabalhados,
      dias_ferias: diasFerias
    };
  }

  /**
   * Calcula horas de um intervalo considerando timezone e turnos que cruzam meia-noite
   * @param {string|Date} startTime - Início do intervalo
   * @param {string|Date} endTime - Fim do intervalo
   * @param {string} timezone - Timezone (default: America/Sao_Paulo)
   * @returns {number} - Horas (decimal)
   */
  function calcIntervalHours(startTime, endTime, timezone = 'America/Sao_Paulo') {
    const start = DateTime.fromJSDate(new Date(startTime), { zone: timezone });
    let end = DateTime.fromJSDate(new Date(endTime), { zone: timezone });

    // Se end <= start, assume cruzamento de meia-noite
    if (end <= start) {
      end = end.plus({ days: 1 });
    }

    let hours = end.diff(start, 'hours').hours;
    // Limita a 24h por intervalo (proteção contra dados inválidos)
    if (hours > 24) {
      hours = 24;
    }

    return Math.round(hours * 100) / 100;
  }

  /**
   * Divide intervalos que cruzam meia-noite em múltiplos dias
   * @param {string|Date} startTime - Início do intervalo
   * @param {string|Date} endTime - Fim do intervalo
   * @param {string} timezone - Timezone
   * @returns {Array} - Array de intervalos por dia [{ date, start, end, hours }]
   */
  function splitIntervalByDay(startTime, endTime, timezone = 'America/Sao_Paulo') {
    const start = DateTime.fromJSDate(new Date(startTime), { zone: timezone });
    const end = DateTime.fromJSDate(new Date(endTime), { zone: timezone });

    const intervals = [];
    let currentStart = start;

    while (currentStart < end) {
      // Fim do dia atual (meia-noite)
      const dayEnd = currentStart.endOf('day');
      const intervalEnd = end < dayEnd ? end : dayEnd;

      const hours = calcIntervalHours(currentStart.toJSDate(), intervalEnd.toJSDate(), timezone);

      intervals.push({
        date: currentStart.toISODate(),
        start: currentStart.toJSDate(),
        end: intervalEnd.toJSDate(),
        hours: hours
      });

      // Próximo dia (meia-noite + 1 segundo)
      currentStart = intervalEnd.plus({ seconds: 1 });
    }

    return intervals;
  }

  module.exports = {
    calcEtapasForDay,
    calcIRPF,
    calcIRPFTradicional,
    calcSalaryMonth,
    computeOverlapMinutes,
    calcIntervalHours,
    splitIntervalByDay
  };


