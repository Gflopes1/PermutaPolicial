// /lib/core/models/preset.dart

import 'dart:convert';

class Preset {
  final int? id;
  final String nome;
  final String cor;
  final double duracao;
  final String tipo;
  final bool flagAbatimento;
  final String? etapaRuleOverride;
  final String visibilidade;
  final List<PresetInterval> intervals;

  Preset({
    this.id,
    required this.nome,
    required this.cor,
    this.duracao = 0.0,
    this.tipo = 'normal',
    this.flagAbatimento = false,
    this.etapaRuleOverride,
    this.visibilidade = 'private',
    this.intervals = const [],
  });

  factory Preset.fromJson(Map<String, dynamic> json) {
    List<PresetInterval> intervalsList = [];
    if (json['intervals_json'] != null) {
      if (json['intervals_json'] is String) {
        try {
          final parsed = jsonDecode('[${json['intervals_json']}]');
          intervalsList = (parsed as List)
              .where((i) => i['start_time'] != null && i['end_time'] != null)
              .map((i) => PresetInterval.fromJson(i))
              .toList();
        } catch (e) {
          intervalsList = [];
        }
      }
    } else if (json['intervals'] != null && json['intervals'] is List) {
      intervalsList = (json['intervals'] as List)
          .where((i) => i is Map && i['start_time'] != null && i['end_time'] != null)
          .map((i) => PresetInterval.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    double toDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }

    return Preset(
      id: json['id'],
      nome: json['nome'],
      cor: json['cor'],
      duracao: toDouble(json['duracao'], 0.0),
      tipo: json['tipo'] ?? 'normal',
      flagAbatimento: json['flag_abatimento'] == 1 || json['flag_abatimento'] == true,
      etapaRuleOverride: json['etapa_rule_override'],
      visibilidade: json['visibilidade'] ?? 'private',
      intervals: intervalsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'cor': cor,
      'duracao': duracao,
      'tipo': tipo,
      'flag_abatimento': flagAbatimento,
      if (etapaRuleOverride != null) 'etapa_rule_override': etapaRuleOverride,
      'visibilidade': visibilidade,
      'intervals': intervals.map((i) => i.toJson()).toList(),
    };
  }
}

class PresetInterval {
  final int? id;
  final String startTime; // HH:mm:ss
  final String endTime; // HH:mm:ss
  final int ordem;

  PresetInterval({
    this.id,
    required this.startTime,
    required this.endTime,
    this.ordem = 0,
  });

  factory PresetInterval.fromJson(Map<String, dynamic> json) {
    // Converte TIME do MySQL para string HH:mm:ss
    String startTime = '';
    String endTime = '';
    
    if (json['start_time'] != null) {
      if (json['start_time'] is String) {
        startTime = json['start_time'];
      } else {
        startTime = json['start_time'].toString();
      }
    }
    
    if (json['end_time'] != null) {
      if (json['end_time'] is String) {
        endTime = json['end_time'];
      } else {
        endTime = json['end_time'].toString();
      }
    }
    
    return PresetInterval(
      id: json['id'],
      startTime: startTime,
      endTime: endTime,
      ordem: json['ordem'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'start_time': startTime,
      'end_time': endTime,
      'ordem': ordem,
    };
  }
}

