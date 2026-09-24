// Modelos do motor experimental de permutas inteligentes

import 'match_results.dart';
import 'permutas_canonical_metrics.dart';

class SmartMatch extends Match {
  final double? score;
  final Map<String, dynamic>? prioridades;
  final String? descricaoResumo;

  SmartMatch({
    required super.id,
    required super.nome,
    super.qso,
    required super.forcaSigla,
    super.unidadeAtual,
    super.municipioAtual,
    super.estadoAtual,
    super.descricaoInteresse,
    super.postoGraduacaoNome,
    super.ocultarNoMapa,
    super.jaSolicitado,
    super.aceitouCompartilhar,
    super.dadosAceitacao,
    super.emDestaque,
    super.distanciaKm,
    super.municipioReferencia,
    super.tipoProximidade,
    this.score,
    this.prioridades,
    this.descricaoResumo,
  });

  factory SmartMatch.fromJson(Map<String, dynamic> json) {
    final base = Match.fromJson(json);
    return SmartMatch(
      id: base.id,
      nome: base.nome,
      qso: base.qso,
      forcaSigla: base.forcaSigla,
      unidadeAtual: base.unidadeAtual,
      municipioAtual: base.municipioAtual,
      estadoAtual: base.estadoAtual,
      descricaoInteresse: base.descricaoInteresse,
      postoGraduacaoNome: base.postoGraduacaoNome,
      ocultarNoMapa: base.ocultarNoMapa,
      jaSolicitado: base.jaSolicitado,
      aceitouCompartilhar: base.aceitouCompartilhar,
      dadosAceitacao: base.dadosAceitacao,
      emDestaque: base.emDestaque,
      distanciaKm: base.distanciaKm,
      municipioReferencia: base.municipioReferencia,
      tipoProximidade: base.tipoProximidade,
      score: _parseScore(json['score']),
      prioridades: json['prioridades'] != null
          ? Map<String, dynamic>.from(json['prioridades'])
          : null,
      descricaoResumo: json['descricao_resumo'] as String?,
    );
  }
}

class CicloNWay {
  final int tamanho;
  final double? score;
  final List<SmartMatch> participantes;
  final List<String> fluxo;
  final double? distanciaKm;
  final bool porAproximacao;

  CicloNWay({
    required this.tamanho,
    this.score,
    required this.participantes,
    required this.fluxo,
    this.distanciaKm,
    this.porAproximacao = false,
  });

  factory CicloNWay.fromJson(Map<String, dynamic> json) {
    return CicloNWay(
      tamanho: json['tamanho'] ?? 0,
      score: _parseScore(json['score']),
      participantes: (json['participantes'] as List? ?? [])
          .map((e) => SmartMatch.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      fluxo: (json['fluxo'] as List? ?? json['fluxo_texto'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      distanciaKm: _parseDouble(json['distancia_km']),
      porAproximacao: json['por_aproximacao'] == true || json['por_aproximacao'] == 1,
    );
  }
}

class GraphStats {
  final int nodes;
  final int edges;
  final int? cyclesFound;
  final int? buildMs;
  final int? cyclesMs;

  GraphStats({
    required this.nodes,
    required this.edges,
    this.cyclesFound,
    this.buildMs,
    this.cyclesMs,
  });

  const GraphStats.zero() : nodes = 0, edges = 0, cyclesFound = null, buildMs = null, cyclesMs = null;

  factory GraphStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return GraphStats(nodes: 0, edges: 0);
    return GraphStats(
      nodes: (json['nodes'] as num?)?.toInt() ?? 0,
      edges: (json['edges'] as num?)?.toInt() ?? 0,
      cyclesFound: (json['cycles_found'] as num?)?.toInt(),
      buildMs: (json['build_ms'] as num?)?.toInt(),
      cyclesMs: (json['cycles_ms'] as num?)?.toInt(),
    );
  }
}

class SmartMatchCacheInfo {
  final bool hit;
  final DateTime? computedAt;
  final DateTime? expiresAt;
  final int? matchCount;

  SmartMatchCacheInfo({
    required this.hit,
    this.computedAt,
    this.expiresAt,
    this.matchCount,
  });

  factory SmartMatchCacheInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return SmartMatchCacheInfo(hit: false);
    return SmartMatchCacheInfo(
      hit: json['hit'] == true,
      computedAt: _parseDate(json['computed_at']),
      expiresAt: _parseDate(json['expires_at']),
      matchCount: json['match_count'] as int?,
    );
  }
}

class SmartMatchResults {
  final Configuracao configuracao;
  final List<SmartMatch> diretas;
  final List<SmartMatch> proximas;
  final List<SmartMatch> interessados;
  final List<MatchTriangular> triangulares;
  final List<CicloNWay> ciclosN;
  final SmartMatchCacheInfo cache;
  final GraphStats graphStats;
  final PermutasCanonicalMetrics? metricas;

  SmartMatchResults({
    required this.configuracao,
    required this.diretas,
    required this.proximas,
    required this.interessados,
    required this.triangulares,
    required this.ciclosN,
    required this.cache,
    this.graphStats = const GraphStats.zero(),
    this.metricas,
  });

  int get totalMatches =>
      diretas.length +
      proximas.length +
      interessados.length +
      triangulares.length +
      ciclosN.length;

  factory SmartMatchResults.fromJson(Map<String, dynamic> json) {
    return SmartMatchResults(
      configuracao: Configuracao.fromJson(json['configuracao'] ?? {}),
      diretas: (json['diretas'] as List? ?? [])
          .map((e) => SmartMatch.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      proximas: (json['proximas'] as List? ?? [])
          .map((e) => SmartMatch.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      interessados: (json['interessados'] as List? ?? [])
          .map((e) => SmartMatch.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      triangulares: (json['triangulares'] as List? ?? [])
          .map((e) => MatchTriangular.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      ciclosN: (json['ciclos_n'] as List? ?? [])
          .map((e) => CicloNWay.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      cache: SmartMatchCacheInfo.fromJson(
        json['cache'] != null ? Map<String, dynamic>.from(json['cache']) : null,
      ),
      graphStats: GraphStats.fromJson(
        json['graph_stats'] != null
            ? Map<String, dynamic>.from(json['graph_stats'])
            : null,
      ),
      metricas: json['metricas'] != null
          ? PermutasCanonicalMetrics.fromJson(Map<String, dynamic>.from(json['metricas']))
          : null,
    );
  }
}

double? _parseScore(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
