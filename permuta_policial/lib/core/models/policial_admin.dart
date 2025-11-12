// /lib/core/models/policial_admin.dart

class PolicialAdmin {
  final int id;
  final String nome;
  final String email;
  final String? idFuncional;
  final String? qso;
  final String statusVerificacao;
  final bool isEmbaixador;
  final DateTime criadoEm;
  final String? forcaSigla;
  final String? forcaNome;
  final String? postoGraduacaoNome;
  final String? unidadeAtualNome;
  final String? municipioAtualNome;
  final String? estadoAtualSigla;

  PolicialAdmin({
    required this.id,
    required this.nome,
    required this.email,
    this.idFuncional,
    this.qso,
    required this.statusVerificacao,
    required this.isEmbaixador,
    required this.criadoEm,
    this.forcaSigla,
    this.forcaNome,
    this.postoGraduacaoNome,
    this.unidadeAtualNome,
    this.municipioAtualNome,
    this.estadoAtualSigla,
  });

  factory PolicialAdmin.fromJson(Map<String, dynamic> json) {
    return PolicialAdmin(
      id: json['id'] as int,
      nome: json['nome'] as String,
      email: json['email'] as String,
      idFuncional: json['id_funcional'] as String?,
      qso: json['qso'] as String?,
      statusVerificacao: json['status_verificacao'] as String,
      isEmbaixador: (json['embaixador'] as int? ?? 0) == 1,
      criadoEm: DateTime.parse(json['criado_em'] as String),
      forcaSigla: json['forca_sigla'] as String?,
      forcaNome: json['forca_nome'] as String?,
      postoGraduacaoNome: json['posto_graduacao_nome'] as String?,
      unidadeAtualNome: json['unidade_atual_nome'] as String?,
      municipioAtualNome: json['municipio_atual_nome'] as String?,
      estadoAtualSigla: json['estado_atual_sigla'] as String?,
    );
  }

  String get statusVerificacaoLabel {
    switch (statusVerificacao) {
      case 'VERIFICADO':
        return 'Verificado';
      case 'PENDENTE':
        return 'Pendente';
      case 'REJEITADO':
        return 'Rejeitado';
      case 'AGUARDANDO_VERIFICACAO_EMAIL':
        return 'Aguardando Email';
      default:
        return statusVerificacao;
    }
  }
}

