// /lib/core/utils/salary_calculator.dart

import '../models/work_day.dart';
import '../models/salary.dart';

class SalaryCalculator {
  /// Calcula o número de etapas para um dia baseado nas horas trabalhadas
  /// [totalHours] - Total de horas do dia
  /// [etapaRule] - Regra de etapas ('per_6h', 'per_8h', 'fixed')
  /// [customValue] - Valor customizado (para regras fixed)
  /// Retorna o número de etapas (sempre arredondado para baixo)
  static int calcEtapasForDay(
    double totalHours, {
    String etapaRule = 'per_6h',
    double? customValue,
  }) {
    if (totalHours <= 0) return 0;

    switch (etapaRule) {
      case 'per_6h':
        return (totalHours / 6).floor();
      case 'per_8h':
        return (totalHours / 8).floor();
      case 'fixed':
        return customValue != null ? customValue.floor() : 0;
      default:
        // Default: 1 etapa a cada 6 horas
        return (totalHours / 6).floor();
    }
  }

  /// Calcula minutos de sobreposição entre dois intervalos
  static int computeOverlapMinutes(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    final overlapStart = start1.isAfter(start2) ? start1 : start2;
    final overlapEnd = end1.isBefore(end2) ? end1 : end2;

    if (overlapStart.isAfter(overlapEnd) || overlapStart.isAtSameMomentAs(overlapEnd)) {
      return 0;
    }

    return overlapEnd.difference(overlapStart).inMinutes;
  }

  /// Tabela progressiva mensal tradicional (Lei 15.270/2025).
  static double _calcIRPFTradicional(double baseCalculo) {
    if (baseCalculo <= 2428.80) return 0;
    if (baseCalculo <= 2826.65) return baseCalculo * 0.075 - 182.16;
    if (baseCalculo <= 3751.05) return baseCalculo * 0.15 - 394.16;
    if (baseCalculo <= 4664.68) return baseCalculo * 0.225 - 675.49;
    return baseCalculo * 0.275 - 908.73;
  }

  /// Calcula IRPF mensal conforme regras de 2026 (Lei 15.270/2025).
  ///
  /// [baseCalculo] — (salário_base + horas_extras) − previdência
  static double calcIRPF(double baseCalculo) {
    if (baseCalculo <= 0) return 0;
    if (baseCalculo <= 5000) return 0;

    final irpfTradicional = _calcIRPFTradicional(baseCalculo).clamp(0.0, double.infinity);
    var irpf = irpfTradicional;

    if (baseCalculo <= 7350) {
      final redutor = 978.62 - (0.133145 * baseCalculo);
      final desconto = redutor.clamp(0.0, irpfTradicional);
      irpf = irpfTradicional - desconto;
    }

    if (baseCalculo > 50000) {
      final irpfmMinimo = baseCalculo * 0.10;
      irpf = irpf > irpfmMinimo ? irpf : irpfmMinimo;
    }

    return ((irpf * 100).round() / 100).clamp(0.0, double.infinity);
  }

  /// Calcula horas de um intervalo considerando timezone e turnos que cruzam meia-noite
  /// [startTime] - Início do intervalo
  /// [endTime] - Fim do intervalo
  /// Retorna horas (decimal)
  static double calcIntervalHours(DateTime startTime, DateTime endTime) {
    Duration diff = endTime.difference(startTime);
    
    if (diff.isNegative) {
      final nextDay = endTime.add(const Duration(days: 1));
      diff = nextDay.difference(startTime);
    }

    var hours = diff.inMinutes / 60.0;
    if (hours > 24) {
      hours = 24;
    }
    
    return ((hours * 100).round()) / 100;
  }

  /// Calcula o salário do mês completo
  /// [workDays] - Array de dias trabalhados
  /// [settings] - Configurações de salário do usuário
  /// [month] - Mês (1-12)
  /// [year] - Ano
  /// Retorna o resultado do cálculo
  static Map<String, dynamic> calcSalaryMonth(
    List<WorkDay> workDays,
    SalarySettings settings,
    int month,
    int year,
  ) {
    // Calcula dias do mês
    final daysInMonth = DateTime(year, month + 1, 0).day;
    var cargaHorariaMes = daysInMonth * (settings.cargaHorariaDia);

    // Totais do mês
    double totalHoras = 0;
    int totalEtapas = 0;
    int diasTrabalhados = 0;
    int diasFerias = 0;
    double horasAbatimento = 0;

    // Processa cada dia
    for (var day in workDays) {
      final dayType = day.tipo;

      if (dayType == 'ferias') {
        diasFerias++;
        continue; // Férias não contam horas/etapas
      }

      if (dayType == 'folga') {
        continue; // Folga não conta
      }

      final isAbatimento =
          day.flagAbatimento || dayType == 'abatimento' || dayType == 'atestado';

      if (isAbatimento) {
        final horasAbat = day.totalHours > 0 ? day.totalHours : settings.abatimentoHoras;
        horasAbatimento += horasAbat;
        continue;
      }

      // Calcula horas do dia
      double horasDia = 0;

      if (day.totalHours > 0) {
        horasDia = day.totalHours;
      }

      if (dayType == 'normal' && horasDia <= 0) {
        continue;
      }

      final etapaRule = day.etapaRuleOverride ?? settings.etapaRule;
      final etapasDia = calcEtapasForDay(horasDia, etapaRule: etapaRule);

      totalHoras += horasDia;
      totalEtapas += etapasDia;
      diasTrabalhados++;
    }

    cargaHorariaMes = (cargaHorariaMes - horasAbatimento).clamp(0.0, double.infinity);

    // Calcula horas extras
    final horasExtras = (totalHoras - cargaHorariaMes).clamp(0.0, double.infinity);

    // Valores monetários
    final valorEtapas = totalEtapas * settings.etapaValue;
    final valorHorasExtras = horasExtras * settings.valorHoraExtra;

    // VA: não creditar se houver dias de férias no mês
    final valeAlimentacao = diasFerias > 0 ? 0 : settings.valeAlimentacao;

    // Outras vantagens (ex: substituição)
    final outrasVantagens = settings.outrasVantagens;

    // Salário (sem VA) e total de recebimentos
    final salarioBrutoFolha = settings.salarioBase + valorHorasExtras + outrasVantagens;
    final salarioBruto = salarioBrutoFolha + valorEtapas;
    final totalRecebimentos = salarioBruto + valeAlimentacao;

    final basePrevidencia = settings.salarioBase + valorHorasExtras;
    final descontoPrevidencia = basePrevidencia * settings.previdenciaAliquota;

    final baseIRPF = (basePrevidencia - descontoPrevidencia).clamp(0.0, double.infinity);
    final descontoIRPF = calcIRPF(baseIRPF);

    final descontoConsignados = settings.descontoConsignados ?? 0;
    final outrosDescontos = settings.outrosDescontos;

    final salarioLiquidoFolha =
        salarioBrutoFolha - descontoPrevidencia - descontoIRPF - descontoConsignados - outrosDescontos;
    final vaMaisEtapas = valeAlimentacao + valorEtapas;
    final salarioLiquido = salarioLiquidoFolha + vaMaisEtapas;

    return {
      'total_horas': (totalHoras * 100).round() / 100,
      'horas_abatimento': (horasAbatimento * 100).round() / 100,
      'carga_horaria_mes': (cargaHorariaMes * 100).round() / 100,
      'horas_extras': (horasExtras * 100).round() / 100,
      'total_etapas': totalEtapas,
      'valor_etapas': (valorEtapas * 100).round() / 100,
      'vale_alimentacao': (valeAlimentacao * 100).round() / 100,
      'outras_vantagens': (outrasVantagens * 100).round() / 100,
      'valor_horas_extras': (valorHorasExtras * 100).round() / 100,
      'salario_base': (settings.salarioBase * 100).round() / 100,
      'salario_bruto': (salarioBruto * 100).round() / 100,
      'total_recebimentos': (totalRecebimentos * 100).round() / 100,
      'base_irpf': (baseIRPF * 100).round() / 100,
      'desconto_previdencia': (descontoPrevidencia * 100).round() / 100,
      'desconto_irpf': (descontoIRPF * 100).round() / 100,
      'desconto_consignados': (descontoConsignados * 100).round() / 100,
      'outros_descontos': (outrosDescontos * 100).round() / 100,
      'salario_liquido': (salarioLiquido * 100).round() / 100,
      'salario_liquido_folha': (salarioLiquidoFolha * 100).round() / 100,
      'va_mais_etapas': (vaMaisEtapas * 100).round() / 100,
      'dias_trabalhados': diasTrabalhados,
      'dias_ferias': diasFerias,
    };
  }
}

