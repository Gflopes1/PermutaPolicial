// /lib/core/models/work_day.dart

import 'dart:convert';

class WorkDay {
  final int? id;
  final DateTime data;
  final int? presetId;
  final String? presetNome;
  final String? presetCor;
  final String? presetTipo;
  final double totalHours;
  final int etapas;
  final String tipo;
  final bool flagAbatimento;
  final String? etapaRuleOverride;
  final String? observacoes;
  final List<WorkInterval> intervals;

  /// Normaliza para meia-noite local (sem componente de hora).
  static DateTime toDateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Formata como YYYY-MM-DD sem conversão de timezone.
  static String formatDateOnly(DateTime date) {
    final d = toDateOnly(date);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  WorkDay({
    this.id,
    required this.data,
    this.presetId,
    this.presetNome,
    this.presetCor,
    this.presetTipo,
    this.totalHours = 0.0,
    this.etapas = 0,
    this.tipo = 'normal',
    this.flagAbatimento = false,
    this.etapaRuleOverride,
    this.observacoes,
    this.intervals = const [],
  });

  factory WorkDay.fromJson(Map<String, dynamic> json) {
    List<WorkInterval> intervalsList = [];
    if (json['intervals_json'] != null) {
      if (json['intervals_json'] is String) {
        // Se for string JSON, parse
        try {
          final parsed = jsonDecode('[${json['intervals_json']}]');
          intervalsList = (parsed as List)
              .where((i) => i['start_time'] != null && i['end_time'] != null)
              .map((i) => WorkInterval.fromJson(i))
              .toList();
        } catch (e) {
          intervalsList = [];
        }
      }
    } else if (json['intervals'] != null && json['intervals'] is List) {
      intervalsList = (json['intervals'] as List)
          .where((i) => i is Map && i['start_time'] != null && i['end_time'] != null)
          .map((i) => WorkInterval.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    // Parse da data - extrai apenas a parte da data (YYYY-MM-DD), ignorando hora/timezone
    // IMPORTANTE: Cria DateTime local (sem timezone) para evitar deslocamento de dias
    DateTime dataParsed;
    try {
      final dateStr = json['data'] as String;
      // Extrai apenas a parte da data (antes do T ou espaço)
      String dateOnly = dateStr;
      if (dateStr.contains('T')) {
        dateOnly = dateStr.split('T')[0];
      } else if (dateStr.contains(' ')) {
        dateOnly = dateStr.split(' ')[0];
      }
      
      // Parse apenas a data (YYYY-MM-DD) - cria DateTime local (sem timezone)
      final parts = dateOnly.split('-');
      if (parts.length == 3) {
        // Cria DateTime local (sem timezone) - isso evita conversão de UTC para local
        dataParsed = DateTime(
          int.parse(parts[0]), // ano
          int.parse(parts[1]), // mês
          int.parse(parts[2]), // dia
        );
        dataParsed = toDateOnly(dataParsed);
      } else {
        // Fallback: tenta extrair data de formato ISO
        if (dateStr.contains('T')) {
          final datePart = dateStr.split('T')[0];
          final dateParts = datePart.split('-');
          if (dateParts.length == 3) {
            dataParsed = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
            );
          } else {
            throw FormatException('Formato de data inválido: $dateStr');
          }
        } else {
          // Último fallback: parse normal (pode causar problemas de timezone)
          final parsed = DateTime.parse(dateStr);
          // Se parseou com timezone, extrai apenas a data local
          dataParsed = DateTime(parsed.year, parsed.month, parsed.day);
        }
      }
    } catch (e) {
      // Fallback final: tenta parse direto e extrai apenas a data
      try {
        final parsed = DateTime.parse(json['data'] as String);
        dataParsed = DateTime(parsed.year, parsed.month, parsed.day);
      } catch (e2) {
        // Se tudo falhar, usa data atual (não ideal, mas evita crash)
        dataParsed = DateTime.now();
      }
    }

    // Parse de total_hours - pode vir como string ou número
    double totalHoursParsed = 0.0;
    if (json['total_hours'] != null) {
      if (json['total_hours'] is String) {
        totalHoursParsed = double.tryParse(json['total_hours']) ?? 0.0;
      } else if (json['total_hours'] is num) {
        totalHoursParsed = (json['total_hours'] as num).toDouble();
      }
    }

    return WorkDay(
      id: json['id'],
      data: dataParsed,
      presetId: json['preset_id'],
      presetNome: json['preset_nome'],
      presetCor: json['preset_cor'],
      presetTipo: json['preset_tipo'],
      totalHours: totalHoursParsed,
      etapas: json['etapas'] ?? 0,
      tipo: json['tipo'] ?? 'normal',
      flagAbatimento: json['flag_abatimento'] == 1 || json['flag_abatimento'] == true,
      etapaRuleOverride: json['etapa_rule_override'] as String?,
      observacoes: json['observacoes'],
      intervals: intervalsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'data': formatDateOnly(data),
      if (presetId != null) 'preset_id': presetId,
      'total_hours': totalHours,
      'etapas': etapas,
      'tipo': tipo,
      'flag_abatimento': flagAbatimento,
      if (observacoes != null) 'observacoes': observacoes,
      'intervals': intervals.map((i) => i.toJson()).toList(),
    };
  }
}

class WorkInterval {
  final int? id;
  final DateTime startTime;
  final DateTime endTime;
  final int duracaoMinutos;

  WorkInterval({
    this.id,
    required this.startTime,
    required this.endTime,
    this.duracaoMinutos = 0,
  });

  factory WorkInterval.fromJson(Map<String, dynamic> json) {
    return WorkInterval(
      id: json['id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      duracaoMinutos: json['duracao_minutos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
    };
  }
}

