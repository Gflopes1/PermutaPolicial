// /lib/core/models/match_results.dart

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
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] ?? 0,
      nome: json['nome'] ?? 'Nome não informado',
      qso: json['qso'],
      forcaSigla: json['forca_sigla'] ?? 'N/A',
      unidadeAtual: json['unidade_atual'],
      municipioAtual: json['municipio_atual'],
      estadoAtual: json['estado_atual'],
      descricaoInteresse: json['descricao_interesse'],
      postoGraduacaoNome: json['posto_graduacao_nome'],
      ocultarNoMapa: json['ocultar_no_mapa'] == 1 || json['ocultar_no_mapa'] == true,
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

  MatchTriangular({
    required this.policialB,
    required this.policialC,
    required this.fluxo,
  });

  factory MatchTriangular.fromJson(Map<String, dynamic> json) {
    return MatchTriangular(
      policialB: Match.fromJson(json['policialB'] ?? {}),
      policialC: Match.fromJson(json['policialC'] ?? {}),
      fluxo: FluxoTriangular.fromJson(json['fluxo'] ?? {}),
    );
  }
}

// Representa as informações de configuração da busca
class Configuracao {
  final bool aceitaPermutaInterestadual;
  final String tipoPermuta;
  final String forcaSigla;
  final String regraPermuta;

  Configuracao({
    required this.aceitaPermutaInterestadual,
    required this.tipoPermuta,
    required this.forcaSigla,
    required this.regraPermuta,
  });

  factory Configuracao.fromJson(Map<String, dynamic> json) {
    return Configuracao(
      aceitaPermutaInterestadual: json['aceita_permuta_interestadual'] ?? false,
      tipoPermuta: json['tipo_permuta'] ?? 'N/A',
      forcaSigla: json['forca_sigla'] ?? 'N/A',
      regraPermuta: json['regra_permuta'] ?? 'Regra não definida.',
    );
  }
}

// A classe principal que encapsula todos os resultados
class FullMatchResults {
  final Configuracao configuracao;
  final List<Match> interessados;
  final List<Match> diretas;
  final List<MatchTriangular> triangulares;

  FullMatchResults({
    required this.configuracao,
    required this.interessados,
    required this.diretas,
    required this.triangulares,
  });

  factory FullMatchResults.fromJson(Map<String, dynamic> json) {
    return FullMatchResults(
      configuracao: Configuracao.fromJson(json['configuracao'] ?? {}),
      interessados: (json['interessados'] as List? ?? []).map((item) => Match.fromJson(item)).toList(),
      diretas: (json['diretas'] as List? ?? []).map((item) => Match.fromJson(item)).toList(),
      triangulares: (json['triangulares'] as List? ?? []).map((item) => MatchTriangular.fromJson(item)).toList(),
    );
  }
}