class EditalResumo {
  final int id;
  final String tipo;
  final String titulo;
  final String? resumo;
  final String? linkPdf;
  final String status;
  final String forcaSigla;
  final String? forcaNome;
  final String? criterioLabel;
  final DateTime? dataAbertura;
  final DateTime? dataEncerramento;
  final bool destacarForca;
  final int totalVagas;

  EditalResumo({
    required this.id,
    required this.tipo,
    required this.titulo,
    this.resumo,
    this.linkPdf,
    required this.status,
    required this.forcaSigla,
    this.forcaNome,
    this.criterioLabel,
    this.dataAbertura,
    this.dataEncerramento,
    this.destacarForca = false,
    this.totalVagas = 0,
  });

  factory EditalResumo.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return EditalResumo(
      id: json['id'] as int,
      tipo: json['tipo'] as String? ?? 'FORMACAO',
      titulo: json['titulo'] as String? ?? '',
      resumo: json['resumo'] as String?,
      linkPdf: json['link_pdf'] as String?,
      status: json['status'] as String? ?? 'ABERTO',
      forcaSigla: json['forca_sigla'] as String? ?? '',
      forcaNome: json['forca_nome'] as String?,
      criterioLabel: json['criterio_label'] as String?,
      dataAbertura: parseDate(json['data_abertura']),
      dataEncerramento: parseDate(json['data_encerramento']),
      destacarForca: json['destacar_forca'] == 1 || json['destacar_forca'] == true,
      totalVagas: (json['total_vagas'] as num?)?.toInt() ?? 0,
    );
  }

  String get tipoLabel =>
      tipo == 'TRANSFERENCIA_INTERNA' ? 'Transferência interna' : 'Formação';

  String get prazoLabel {
    if (dataEncerramento != null) {
      final d = dataEncerramento!;
      return 'Até ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    return 'Prazo não informado';
  }
}

class EditalDetalhe extends EditalResumo {
  final bool temAcesso;
  final bool agenteVerificado;
  final String? motivoSemAcesso;
  final int? minhaPosicao;
  final String? criterioPrioridade;
  final int maxOpcoes;

  EditalDetalhe({
    required super.id,
    required super.tipo,
    required super.titulo,
    super.resumo,
    super.linkPdf,
    required super.status,
    required super.forcaSigla,
    super.forcaNome,
    super.criterioLabel,
    super.dataAbertura,
    super.dataEncerramento,
    super.destacarForca,
    super.totalVagas,
    required this.temAcesso,
    this.agenteVerificado = false,
    this.motivoSemAcesso,
    this.minhaPosicao,
    this.criterioPrioridade,
    this.maxOpcoes = 3,
  });

  factory EditalDetalhe.fromJson(Map<String, dynamic> json) {
    final base = EditalResumo.fromJson(json);
    return EditalDetalhe(
      id: base.id,
      tipo: base.tipo,
      titulo: base.titulo,
      resumo: base.resumo,
      linkPdf: base.linkPdf,
      status: base.status,
      forcaSigla: base.forcaSigla,
      forcaNome: base.forcaNome,
      criterioLabel: base.criterioLabel,
      dataAbertura: base.dataAbertura,
      dataEncerramento: base.dataEncerramento,
      destacarForca: base.destacarForca,
      totalVagas: base.totalVagas,
      temAcesso: json['tem_acesso'] == true || json['tem_acesso'] == 1,
      agenteVerificado: json['agente_verificado'] == true || json['agente_verificado'] == 1,
      motivoSemAcesso: json['motivo_sem_acesso']?.toString(),
      minhaPosicao: (json['minha_posicao'] as num?)?.toInt(),
      criterioPrioridade: json['criterio_prioridade'] as String?,
      maxOpcoes: (json['max_opcoes'] as num?)?.toInt() ?? 3,
    );
  }
}
