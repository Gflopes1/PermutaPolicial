// /lib/core/models/user_profile.dart

class UserProfile {
  final int id;
  final int? forcaId;
  final String nome;
  final String? email;
  final String? idFuncional;
  final String? qso;
  final String? antiguidade;
  final String? unidadeAtualNome;
  final int? unidadeAtualId;
  final String? municipioAtualNome;
  final int? municipioAtualId;
  final String? estadoAtualSigla;
  final int? estadoAtualId;
  final bool lotacaoInterestadual;
  final bool? ocultarNoMapa;
  final bool alertasMatchAtivo;
  final bool emDestaque;
  final bool isEmbaixador;
  final bool isModerator;
  final int? postoGraduacaoId;
  final String? postoGraduacaoNome;
  final String? tipoPermuta;
  final String? forcaSigla;
  final bool isPremium;
  final String? fotoPerfil;
  final Map<String, dynamic>? subscription;
  final bool agenteVerificado;
  final String? metodoVerificacao;
  final String? verificadoEm;

  /// Admin ou moderador global (campo legado `embaixador` = admin master).
  bool get isAdmin => isEmbaixador || isModerator;

  UserProfile({
    required this.id,
    this.forcaId,
    required this.nome,
    this.email,
    this.idFuncional,
    this.qso,
    this.antiguidade,
    this.unidadeAtualNome,
    this.unidadeAtualId,
    this.municipioAtualNome,
    this.municipioAtualId,
    this.estadoAtualSigla,
    this.estadoAtualId,
    required this.lotacaoInterestadual,
    this.ocultarNoMapa,
    this.alertasMatchAtivo = true,
    this.emDestaque = false,
    required this.isEmbaixador,
    this.isModerator = false,
    this.postoGraduacaoId,
    this.postoGraduacaoNome,
    this.tipoPermuta,
    this.forcaSigla,
    this.isPremium = false,
    this.fotoPerfil,
    this.subscription,
    this.agenteVerificado = false,
    this.metodoVerificacao,
    this.verificadoEm,
  });

  // Helper para parsear boolean de várias formas
  static bool _parseBoolean(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final parsedIsPremium = _parseBoolean(json['is_premium']);

    return UserProfile(
      id: _parseInt(json['id']) ?? 0,
      forcaId: _parseInt(json['forca_id']),
      nome: json['nome'] ?? 'Usuário',
      email: json['email'],
      idFuncional: json['id_funcional'],
      qso: json['qso'],
      antiguidade: json['antiguidade'],
      unidadeAtualNome: json['unidade_atual_nome'],
      unidadeAtualId: _parseInt(json['unidade_atual_id']),
      municipioAtualNome: json['municipio_atual_nome'],
      municipioAtualId: _parseInt(json['municipio_id']),
      estadoAtualSigla: json['estado_atual_sigla'],
      estadoAtualId: _parseInt(json['estado_id']),
      lotacaoInterestadual: _parseBoolean(json['lotacao_interestadual']),
      ocultarNoMapa: _parseBoolean(json['ocultar_no_mapa']),
      alertasMatchAtivo: json['alertas_match_ativo'] == null ? true : _parseBoolean(json['alertas_match_ativo']),
      emDestaque: _parseBoolean(json['em_destaque']),
      isEmbaixador: _parseBoolean(json['embaixador']),
      isModerator: _parseBoolean(json['is_moderator']),
      postoGraduacaoId: _parseInt(json['posto_graduacao_id']),
      postoGraduacaoNome: json['posto_graduacao_nome'],
      tipoPermuta: json['forca_tipo_permuta'],
      forcaSigla: json['forca_sigla'],
      isPremium: parsedIsPremium,
      fotoPerfil: json['foto_perfil'] as String?,
      subscription: json['subscription'] != null 
          ? Map<String, dynamic>.from(json['subscription']) 
          : null,
      agenteVerificado: _parseBoolean(json['agente_verificado']),
      metodoVerificacao: json['metodo_verificacao']?.toString(),
      verificadoEm: json['verificado_em']?.toString(),
    );
  }
}
