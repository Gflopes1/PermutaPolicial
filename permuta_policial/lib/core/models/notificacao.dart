// /lib/core/models/notificacao.dart

class Notificacao {
  final int id;
  final int usuarioId;
  final String tipo;
  final int? referenciaId;
  final String titulo;
  final String? mensagem;
  final bool lida;
  final DateTime criadoEm;
  
  // Dados do solicitante (quando tipo é SOLICITACAO_CONTATO)
  final String? solicitanteNome;
  final String? solicitanteContato;
  final String? solicitanteForcaNome;
  final String? solicitanteForcaSigla;
  final String? solicitanteEstadoSigla;
  final String? solicitanteCidadeNome;
  final String? solicitantePostoNome;
  
  // Dados do aceitador (quando tipo é SOLICITACAO_CONTATO_ACEITA)
  final String? aceitadorNome;
  final String? aceitadorContato;
  final String? aceitadorForcaNome;
  final String? aceitadorForcaSigla;
  final String? aceitadorEstadoSigla;
  final String? aceitadorCidadeNome;
  final String? aceitadorUnidadeNome;
  final String? aceitadorPostoNome;

  Notificacao({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    this.referenciaId,
    required this.titulo,
    this.mensagem,
    required this.lida,
    required this.criadoEm,
    this.solicitanteNome,
    this.solicitanteContato,
    this.solicitanteForcaNome,
    this.solicitanteForcaSigla,
    this.solicitanteEstadoSigla,
    this.solicitanteCidadeNome,
    this.solicitantePostoNome,
    this.aceitadorNome,
    this.aceitadorContato,
    this.aceitadorForcaNome,
    this.aceitadorForcaSigla,
    this.aceitadorEstadoSigla,
    this.aceitadorCidadeNome,
    this.aceitadorUnidadeNome,
    this.aceitadorPostoNome,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    return Notificacao(
      id: json['id'],
      usuarioId: json['usuario_id'],
      tipo: json['tipo'],
      referenciaId: json['referencia_id'],
      titulo: json['titulo'],
      mensagem: json['mensagem'],
      lida: json['lida'] == 1 || json['lida'] == true,
      criadoEm: DateTime.parse(json['criado_em']),
      solicitanteNome: json['solicitante_nome'],
      solicitanteContato: json['solicitante_contato'],
      solicitanteForcaNome: json['solicitante_forca_nome'],
      solicitanteForcaSigla: json['solicitante_forca_sigla'],
      solicitanteEstadoSigla: json['solicitante_estado_sigla'],
      solicitanteCidadeNome: json['solicitante_cidade_nome'],
      solicitantePostoNome: json['solicitante_posto_nome'],
      aceitadorNome: json['aceitador_nome'],
      aceitadorContato: json['aceitador_contato'],
      aceitadorForcaNome: json['aceitador_forca_nome'],
      aceitadorForcaSigla: json['aceitador_forca_sigla'],
      aceitadorEstadoSigla: json['aceitador_estado_sigla'],
      aceitadorCidadeNome: json['aceitador_cidade_nome'],
      aceitadorUnidadeNome: json['aceitador_unidade_nome'],
      aceitadorPostoNome: json['aceitador_posto_nome'],
    );
  }
}

