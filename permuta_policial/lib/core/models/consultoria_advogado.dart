class ConsultoriaAdvogado {
  final int id;
  final String nome;
  final String descricaoCurta;
  final String? descricaoDetalhada;
  final String fotoUrl;
  final String? siteUrl;
  final String? contatoWhatsapp;
  final String? contatoTelefone;
  final String? contatoEmail;
  final int ordem;
  final bool ativo;

  ConsultoriaAdvogado({
    required this.id,
    required this.nome,
    required this.descricaoCurta,
    this.descricaoDetalhada,
    required this.fotoUrl,
    this.siteUrl,
    this.contatoWhatsapp,
    this.contatoTelefone,
    this.contatoEmail,
    this.ordem = 0,
    this.ativo = true,
  });

  factory ConsultoriaAdvogado.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return ConsultoriaAdvogado(
      id: parseInt(json['id']),
      nome: json['nome'] as String? ?? '',
      descricaoCurta: json['descricao_curta'] as String? ?? '',
      descricaoDetalhada: json['descricao_detalhada'] as String?,
      fotoUrl: json['foto_url'] as String? ?? '',
      siteUrl: json['site_url'] as String?,
      contatoWhatsapp: json['contato_whatsapp'] as String?,
      contatoTelefone: json['contato_telefone'] as String?,
      contatoEmail: json['contato_email'] as String?,
      ordem: parseInt(json['ordem']),
      ativo: json['ativo'] == true || json['ativo'] == 1,
    );
  }

  bool get hasContato =>
      (contatoWhatsapp?.isNotEmpty ?? false) ||
      (contatoTelefone?.isNotEmpty ?? false) ||
      (contatoEmail?.isNotEmpty ?? false);

  bool get hasSite => siteUrl?.isNotEmpty ?? false;
}

class ConsultoriaClickStats {
  final int advogadoId;
  final String advogadoNome;
  final int cliquesContato;
  final int cliquesSite;
  final int cliquesTotal;

  ConsultoriaClickStats({
    required this.advogadoId,
    required this.advogadoNome,
    required this.cliquesContato,
    required this.cliquesSite,
    required this.cliquesTotal,
  });

  factory ConsultoriaClickStats.fromJson(Map<String, dynamic> json) {
    int n(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
    return ConsultoriaClickStats(
      advogadoId: n(json['id'] ?? json['advogado_id']),
      advogadoNome: json['nome'] as String? ?? json['advogado_nome'] as String? ?? '',
      cliquesContato: n(json['cliques_contato']),
      cliquesSite: n(json['cliques_site']),
      cliquesTotal: n(json['cliques_total'] ?? json['total']),
    );
  }
}

class ConsultoriaClickByUser {
  final int advogadoId;
  final String advogadoNome;
  final String tipoClique;
  final int? usuarioId;
  final String? usuarioNome;
  final String? usuarioEmail;
  final int total;

  ConsultoriaClickByUser({
    required this.advogadoId,
    required this.advogadoNome,
    required this.tipoClique,
    this.usuarioId,
    this.usuarioNome,
    this.usuarioEmail,
    required this.total,
  });

  factory ConsultoriaClickByUser.fromJson(Map<String, dynamic> json) {
    int? userId;
    final rawUser = json['usuario_id'];
    if (rawUser != null) userId = rawUser is int ? rawUser : int.tryParse('$rawUser');

    return ConsultoriaClickByUser(
      advogadoId: json['advogado_id'] is int
          ? json['advogado_id'] as int
          : int.tryParse('${json['advogado_id']}') ?? 0,
      advogadoNome: json['advogado_nome'] as String? ?? '',
      tipoClique: json['tipo_clique'] as String? ?? '',
      usuarioId: userId,
      usuarioNome: json['usuario_nome'] as String?,
      usuarioEmail: json['usuario_email'] as String?,
      total: json['total'] is int ? json['total'] as int : int.tryParse('${json['total']}') ?? 0,
    );
  }
}
