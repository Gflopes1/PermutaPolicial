// /lib/core/models/match_results.dart

import 'permutas_canonical_metrics.dart';

// Representa um policial encontrado em uma das listas de match
class Match {
  final int id;
  final String nome;
  final String? qso;
  final String forcaSigla;
  final String? unidadeAtual;
  final String? municipioAtual;
  final String? estadoAtual;
  final String? descricaoInteresse;
  final String? postoGraduacaoNome;
  final bool ocultarNoMapa;
  final bool jaSolicitado;
  final bool aceitouCompartilhar;
  final Map<String, dynamic>? dadosAceitacao;
  final bool emDestaque;
  final double? distanciaKm;
  final String? municipioReferencia;
  final String? tipoProximidade;

  Match({
    required this.id,
    required this.nome,
    this.qso,
    required this.forcaSigla,
    this.unidadeAtual,
    this.municipioAtual,
    this.estadoAtual,
    this.descricaoInteresse,
    this.postoGraduacaoNome,
    this.ocultarNoMapa = false,
    this.jaSolicitado = false,
    this.aceitouCompartilhar = false,
    this.dadosAceitacao,
    this.emDestaque = false,
    this.distanciaKm,
    this.municipioReferencia,
    this.tipoProximidade,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: _parseId(json['id'] ?? json['policial_id']),
      nome: json['nome'] ?? 'Nome não informado',
      qso: json['qso'],
      forcaSigla: json['forca_sigla'] ?? json['forcaSigla'] ?? 'N/A',
      unidadeAtual: json['unidade_atual'] ?? json['unidadeAtual'],
      municipioAtual: json['municipio_atual'] ?? json['municipioAtual'],
      estadoAtual: json['estado_atual'] ?? json['estadoAtual'],
      descricaoInteresse: json['descricao_interesse'],
      postoGraduacaoNome: json['posto_graduacao_nome'] ?? json['postoGraduacaoNome'],
      ocultarNoMapa: json['ocultar_no_mapa'] == 1 || json['ocultar_no_mapa'] == true,
      jaSolicitado: json['ja_solicitado'] == true || json['ja_solicitado'] == 1,
      aceitouCompartilhar: json['aceitou_compartilhar'] == true || json['aceitou_compartilhar'] == 1,
      dadosAceitacao: json['dados_aceitacao'] != null ? Map<String, dynamic>.from(json['dados_aceitacao']) : null,
      emDestaque: json['em_destaque'] == 1 || json['em_destaque'] == true,
      distanciaKm: json['distancia_km'] != null
          ? (json['distancia_km'] is num
              ? (json['distancia_km'] as num).toDouble()
              : double.tryParse(json['distancia_km'].toString()))
          : null,
      municipioReferencia: json['municipio_referencia'],
      tipoProximidade: json['tipo_proximidade'],
    );
  }

  static int _parseId(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
  
  Match copyWith({
    int? id,
    String? nome,
    String? qso,
    String? forcaSigla,
    String? unidadeAtual,
    String? municipioAtual,
    String? estadoAtual,
    String? descricaoInteresse,
    String? postoGraduacaoNome,
    bool? ocultarNoMapa,
    bool? jaSolicitado,
    bool? aceitouCompartilhar,
    Map<String, dynamic>? dadosAceitacao,
    bool? emDestaque,
    double? distanciaKm,
    String? municipioReferencia,
    String? tipoProximidade,
  }) {
    return Match(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      qso: qso ?? this.qso,
      forcaSigla: forcaSigla ?? this.forcaSigla,
      unidadeAtual: unidadeAtual ?? this.unidadeAtual,
      municipioAtual: municipioAtual ?? this.municipioAtual,
      estadoAtual: estadoAtual ?? this.estadoAtual,
      descricaoInteresse: descricaoInteresse ?? this.descricaoInteresse,
      postoGraduacaoNome: postoGraduacaoNome ?? this.postoGraduacaoNome,
      ocultarNoMapa: ocultarNoMapa ?? this.ocultarNoMapa,
      jaSolicitado: jaSolicitado ?? this.jaSolicitado,
      aceitouCompartilhar: aceitouCompartilhar ?? this.aceitouCompartilhar,
      dadosAceitacao: dadosAceitacao ?? this.dadosAceitacao,
      emDestaque: emDestaque ?? this.emDestaque,
      distanciaKm: distanciaKm ?? this.distanciaKm,
      municipioReferencia: municipioReferencia ?? this.municipioReferencia,
      tipoProximidade: tipoProximidade ?? this.tipoProximidade,
    );
  }
}

// Representa o fluxo de uma permuta triangular
class FluxoTriangular {
  final String aParaB;
  final String bParaC;
  final String cParaA;

  FluxoTriangular({required this.aParaB, required this.bParaC, required this.cParaA});

  factory FluxoTriangular.fromJson(Map<String, dynamic> json) {
    return FluxoTriangular(
      aParaB: json['a_para_b'] ?? 'N/A',
      bParaC: json['b_para_c'] ?? 'N/A',
      cParaA: json['c_para_a'] ?? 'N/A',
    );
  }
}

// Representa um resultado de permuta triangular completo
class MatchTriangular {
  final Match policialB;
  final Match policialC;
  final FluxoTriangular fluxo;
  final double? distanciaKm;
  final bool porAproximacao;

  MatchTriangular({
    required this.policialB,
    required this.policialC,
    required this.fluxo,
    this.distanciaKm,
    this.porAproximacao = false,
  });

  factory MatchTriangular.fromJson(Map<String, dynamic> json) {
    double? parseDist(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return MatchTriangular(
      policialB: Match.fromJson(json['policialB'] ?? json['policial_b'] ?? {}),
      policialC: Match.fromJson(json['policialC'] ?? json['policial_c'] ?? {}),
      fluxo: FluxoTriangular.fromJson(json['fluxo'] ?? {}),
      distanciaKm: parseDist(json['distancia_km']),
      porAproximacao: json['por_aproximacao'] == true || json['por_aproximacao'] == 1,
    );
  }
}

// Representa as informações de configuração da busca
class Configuracao {
  final bool aceitaPermutaInterestadual;
  final String tipoPermuta;
  final String forcaSigla;
  final String regraPermuta;
  final bool temRaioConfigurado;

  Configuracao({
    required this.aceitaPermutaInterestadual,
    required this.tipoPermuta,
    required this.forcaSigla,
    required this.regraPermuta,
    this.temRaioConfigurado = false,
  });

  factory Configuracao.fromJson(Map<String, dynamic> json) {
    return Configuracao(
      aceitaPermutaInterestadual: json['aceita_permuta_interestadual'] ?? false,
      tipoPermuta: json['tipo_permuta'] ?? 'N/A',
      forcaSigla: json['forca_sigla'] ?? 'N/A',
      regraPermuta: json['regra_permuta'] ?? 'Regra não definida.',
      temRaioConfigurado: json['tem_raio_configurado'] == true || json['tem_raio_configurado'] == 1,
    );
  }
}

// A classe principal que encapsula todos os resultados
class FullMatchResults {
  final Configuracao configuracao;
  final List<Match> interessados;
  final List<Match> diretas;
  final List<MatchTriangular> triangulares;
  final List<MatchTriangular> triangularesProximas;
  final List<Match> proximas;
  final PermutasCanonicalMetrics? metricas;

  FullMatchResults({
    required this.configuracao,
    required this.interessados,
    required this.diretas,
    required this.triangulares,
    this.triangularesProximas = const [],
    this.proximas = const [],
    this.metricas,
  });

  factory FullMatchResults.fromJson(Map<String, dynamic> json) {
    return FullMatchResults(
      configuracao: Configuracao.fromJson(json['configuracao'] ?? {}),
      interessados: (json['interessados'] as List? ?? []).map((item) => Match.fromJson(item)).toList(),
      diretas: (json['diretas'] as List? ?? []).map((item) => Match.fromJson(item)).toList(),
      triangulares: (json['triangulares'] as List? ?? []).map((item) => MatchTriangular.fromJson(item)).toList(),
      triangularesProximas: (json['triangulares_proximas'] as List? ?? [])
          .map((item) => MatchTriangular.fromJson(item))
          .toList(),
      proximas: (json['proximas'] as List? ?? []).map((item) => Match.fromJson(item)).toList(),
      metricas: json['metricas'] != null
          ? PermutasCanonicalMetrics.fromJson(Map<String, dynamic>.from(json['metricas']))
          : null,
    );
  }
}