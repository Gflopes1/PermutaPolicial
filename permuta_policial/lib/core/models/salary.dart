// /lib/core/models/salary.dart

class SalarySettings {
  final int? id;
  final double cargaHorariaDia;
  final double valorHoraExtra;
  final double valeAlimentacao;
  final int diaPagamentoVa;
  final double etapaValue;
  final double previdenciaAliquota;
  final String etapaRule;
  final double abatimentoHoras;
  final double salarioBase;
  final double? descontoConsignados;
  final double outrosDescontos;
  final double outrasVantagens;

  SalarySettings({
    this.id,
    this.cargaHorariaDia = 5.7,
    this.valorHoraExtra = 44.0,
    this.valeAlimentacao = 426.0,
    this.diaPagamentoVa = 20,
    this.etapaValue = 11.0,
    this.previdenciaAliquota = 0.14,
    this.etapaRule = 'per_6h',
    this.abatimentoHoras = 5.7,
    this.salarioBase = 0.0,
    this.descontoConsignados,
    this.outrosDescontos = 0.0,
    this.outrasVantagens = 0.0,
  });

  factory SalarySettings.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return SalarySettings(
      id: json['id'],
      cargaHorariaDia: toDouble(json['carga_horaria_dia'], 5.7),
      valorHoraExtra: toDouble(json['valor_hora_extra'], 44.0),
      valeAlimentacao: toDouble(json['vale_alimentacao'], 426.0),
      diaPagamentoVa: json['dia_pagamento_va'] ?? 20,
      etapaValue: toDouble(json['etapa_value'], 11.0),
      previdenciaAliquota: toDouble(json['previdencia_aliquota'], 0.14),
      etapaRule: json['etapa_rule'] ?? 'per_6h',
      abatimentoHoras: toDouble(json['abatimento_horas'], 5.7),
      salarioBase: toDouble(json['salario_base'], 0.0),
      descontoConsignados: json['desconto_consignados'] != null 
          ? toDouble(json['desconto_consignados'], 0.0)
          : null,
      outrosDescontos: toDouble(json['outros_descontos'], 0.0),
      outrasVantagens: toDouble(json['outras_vantagens'], 0.0),
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    return {
      if (includeId && id != null) 'id': id,
      'carga_horaria_dia': cargaHorariaDia,
      'valor_hora_extra': valorHoraExtra,
      'vale_alimentacao': valeAlimentacao,
      'dia_pagamento_va': diaPagamentoVa,
      'etapa_value': etapaValue,
      'previdencia_aliquota': previdenciaAliquota,
      'etapa_rule': etapaRule,
      'abatimento_horas': abatimentoHoras,
      'salario_base': salarioBase,
      if (descontoConsignados != null) 'desconto_consignados': descontoConsignados,
      'outros_descontos': outrosDescontos,
      'outras_vantagens': outrasVantagens,
    };
  }
}

class SalaryResult {
  final int? id;
  final int mes;
  final int ano;
  final double totalHoras;
  final double cargaHorariaMes;
  final double horasExtras;
  final int totalEtapas;
  final double valorEtapas;
  final double valeAlimentacao;
  final double valorHorasExtras;
  final double salarioBruto;
  final double descontoPrevidencia;
  final double descontoIrpf;
  final double descontoConsignados;
  final double outrosDescontos;
  final double outrasVantagens;
  final double salarioLiquido;
  final int diasTrabalhados;
  final int diasFerias;
  final String status;

  SalaryResult({
    this.id,
    required this.mes,
    required this.ano,
    this.totalHoras = 0.0,
    this.cargaHorariaMes = 0.0,
    this.horasExtras = 0.0,
    this.totalEtapas = 0,
    this.valorEtapas = 0.0,
    this.valeAlimentacao = 0.0,
    this.valorHorasExtras = 0.0,
    this.salarioBruto = 0.0,
    this.descontoPrevidencia = 0.0,
    this.descontoIrpf = 0.0,
    this.descontoConsignados = 0.0,
    this.outrosDescontos = 0.0,
    this.outrasVantagens = 0.0,
    this.salarioLiquido = 0.0,
    this.diasTrabalhados = 0,
    this.diasFerias = 0,
    this.status = 'PENDENTE',
  });

  factory SalaryResult.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return SalaryResult(
      id: json['id'],
      mes: json['mes'],
      ano: json['ano'],
      totalHoras: toDouble(json['total_horas'], 0.0),
      cargaHorariaMes: toDouble(json['carga_horaria_mes'], 0.0),
      horasExtras: toDouble(json['horas_extras'], 0.0),
      totalEtapas: json['total_etapas'] ?? 0,
      valorEtapas: toDouble(json['valor_etapas'], 0.0),
      valeAlimentacao: toDouble(json['vale_alimentacao'], 0.0),
      valorHorasExtras: toDouble(json['valor_horas_extras'], 0.0),
      salarioBruto: toDouble(json['salario_bruto'], 0.0),
      descontoPrevidencia: toDouble(json['desconto_previdencia'], 0.0),
      descontoIrpf: toDouble(json['desconto_irpf'], 0.0),
      descontoConsignados: toDouble(json['desconto_consignados'], 0.0),
      outrosDescontos: toDouble(json['outros_descontos'], 0.0),
      outrasVantagens: toDouble(json['outras_vantagens'], 0.0),
      salarioLiquido: toDouble(json['salario_liquido'], 0.0),
      diasTrabalhados: json['dias_trabalhados'] ?? 0,
      diasFerias: json['dias_ferias'] ?? 0,
      status: json['status'] ?? 'PENDENTE',
    );
  }
}


