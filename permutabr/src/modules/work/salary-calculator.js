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
 * Calcula IRPF baseado na tabela progressiva mensal
 * 
 * IMPORTANTE: A tabela de IRPF está armazenada no banco de dados (tabela irpf_faixas)
 * para facilitar atualizações futuras. Os valores abaixo são usados como fallback.
 * 
 * Tabela IRPF 2024 (valores mensais):
 * - Até R$ 2.428,80: Isento
 * - De R$ 2.428,81 até R$ 2.826,65: 7,5% - Dedução R$ 182,16
 * - De R$ 2.826,66 até R$ 3.751,05: 15,0% - Dedução R$ 394,16
 * - De R$ 3.751,06 até R$ 4.664,68: 22,5% - Dedução R$ 675,49
 * - Acima de R$ 4.664,68: 27,5% - Dedução R$ 908,73
 * 
 * Fórmula: (base de cálculo) * alíquota - dedução
 * Base de cálculo = salário bruto - previdência
 * 
 * Para atualizar a tabela de IRPF, execute a migration create_irpf_table.sql
 * ou atualize diretamente a tabela irpf_faixas no banco de dados.
 * 
 * @param {number} baseCalculo - Base de cálculo (salário bruto - previdência)
 * @returns {number} - Valor do IRPF
 */
function calcIRPF(baseCalculo) {
  // Garante que baseCalculo não seja negativo
  if (baseCalculo <= 0) {
    return 0;
  }
  
  // Tabela IRPF 2024 (valores mensais)
  if (baseCalculo <= 2428.80) {
    return 0; // Isento
  } else if (baseCalculo <= 2826.65) {
    // 7,5% - Dedução: R$ 182,16
    const irpf = baseCalculo * 0.075 - 182.16;
    return Math.max(0, Math.round(irpf * 100) / 100);
  } else if (baseCalculo <= 3751.05) {
    // 15,0% - Dedução: R$ 394,16
    const irpf = baseCalculo * 0.15 - 394.16;
    return Math.max(0, Math.round(irpf * 100) / 100);
  } else if (baseCalculo <= 4664.68) {
    // 22,5% - Dedução: R$ 675,49
    const irpf = baseCalculo * 0.225 - 675.49;
    return Math.max(0, Math.round(irpf * 100) / 100);
  } else {
    // 27,5% - Dedução: R$ 908,73
    const irpf = baseCalculo * 0.275 - 908.73;
    return Math.max(0, Math.round(irpf * 100) / 100);
  }
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
  const cargaHorariaMes = daysInMonth * (settings.carga_horaria_dia || 5.70);

  // Totais do mês
  let totalHoras = 0;
  let totalEtapas = 0;
  let diasTrabalhados = 0;
  let diasFerias = 0;

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

    // Calcula horas do dia
    let horasDia = 0;
    
    if (day.total_hours && day.total_hours > 0) {
      horasDia = parseFloat(day.total_hours);
    } else if (day.flag_abatimento || dayType === 'abatimento' || dayType === 'atestado') {
      // Abatimento/atestado usa valor configurado
      horasDia = settings.abatimento_horas || 5.70;
    }

    // Calcula etapas do dia
    const etapaRule = day.etapa_rule_override || settings.etapa_rule || 'per_6h';
    const etapasDia = calcEtapasForDay(horasDia, etapaRule);

    totalHoras += horasDia;
    totalEtapas += etapasDia;
    diasTrabalhados++;
  });

  // Calcula horas extras
  const horasExtras = Math.max(0, totalHoras - cargaHorariaMes);

  // Valores monetários
  const valorEtapas = totalEtapas * (settings.etapa_value || 11.00);
  const valorHorasExtras = horasExtras * (settings.valor_hora_extra || 44.00);
  
  // VA: não creditar se houver dias de férias no mês
  const valeAlimentacao = diasFerias > 0 ? 0 : (settings.vale_alimentacao || 426.00);

  // Outras vantagens (ex: substituição)
  const outrasVantagens = settings.outras_vantagens || 0;

  // Salário bruto (base + extras + etapas + VA + outras vantagens)
  // Nota: VA e Etapas são isentas de IR, mas entram no bruto
  const salarioBruto = (settings.salario_base || 0) + valorHorasExtras + valorEtapas + valeAlimentacao + outrasVantagens;

  // Descontos
  // Previdência: calcula sobre salário base + horas extras (não sobre VA/etapas/vantagens)
  const basePrevidencia = (settings.salario_base || 0) + valorHorasExtras;
  const descontoPrevidencia = basePrevidencia * (settings.previdencia_aliquota || 0.14);

  // IRPF: calcula sobre base (salário bruto - previdência)
  // Fórmula: (salário bruto - previdência) * alíquota - dedução
  // VA, etapas e outras vantagens entram no salário bruto, mas são isentas de IR
  // A base de cálculo do IRPF é: salário bruto - previdência
  const baseIRPF = Math.max(0, salarioBruto - descontoPrevidencia);
  const descontoIRPF = calcIRPF(baseIRPF);
  
  // Debug: log para verificar cálculo do IRPF
  if (baseIRPF > 0) {
    console.log(`[IRPF Debug] Salário Bruto: R$ ${salarioBruto.toFixed(2)}, Previdência: R$ ${descontoPrevidencia.toFixed(2)}, Base IRPF: R$ ${baseIRPF.toFixed(2)}, IRPF: R$ ${descontoIRPF.toFixed(2)}`);
  }

  // Descontos consignados (opcional, vem das settings se existir)
  const descontoConsignados = settings.desconto_consignados || 0;

  // Outros descontos em folha
  const outrosDescontos = settings.outros_descontos || 0;

  // Salário líquido
  const salarioLiquido = salarioBruto - descontoPrevidencia - descontoIRPF - descontoConsignados - outrosDescontos;

  return {
    total_horas: Math.round(totalHoras * 100) / 100,
    carga_horaria_mes: Math.round(cargaHorariaMes * 100) / 100,
    horas_extras: Math.round(horasExtras * 100) / 100,
    total_etapas: totalEtapas,
    valor_etapas: Math.round(valorEtapas * 100) / 100,
    vale_alimentacao: Math.round(valeAlimentacao * 100) / 100,
    outras_vantagens: Math.round(outrasVantagens * 100) / 100,
    valor_horas_extras: Math.round(valorHorasExtras * 100) / 100,
    salario_base: Math.round((settings.salario_base || 0) * 100) / 100,
    salario_bruto: Math.round(salarioBruto * 100) / 100,
    desconto_previdencia: Math.round(descontoPrevidencia * 100) / 100,
    desconto_irpf: Math.round(descontoIRPF * 100) / 100,
    desconto_consignados: Math.round(descontoConsignados * 100) / 100,
    outros_descontos: Math.round(outrosDescontos * 100) / 100,
    salario_liquido: Math.round(salarioLiquido * 100) / 100,
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
  const end = DateTime.fromJSDate(new Date(endTime), { zone: timezone });

  // Se end < start, significa que cruzou meia-noite
  let diff = end.diff(start, 'hours');
  if (diff.hours < 0) {
    // Adiciona 24 horas
    diff = end.plus({ days: 1 }).diff(start, 'hours');
  }

  return Math.round(diff.hours * 100 + diff.minutes / 60 * 100) / 100;
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
  calcSalaryMonth,
  computeOverlapMinutes,
  calcIntervalHours,
  splitIntervalByDay
};


