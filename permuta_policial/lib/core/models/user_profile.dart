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
  final String? municipioAtualNome;
  final String? estadoAtualSigla;
  final bool lotacaoInterestadual;
  final bool? ocultarNoMapa;
  final bool isEmbaixador;
  final int? postoGraduacaoId;
  final String? postoGraduacaoNome;
  final String? tipoPermuta;
  final String? forcaSigla;

  UserProfile({
    required this.id,
    this.forcaId,
    required this.nome,
    this.email,
    this.idFuncional,
    this.qso,
    this.antiguidade,
    this.unidadeAtualNome,
    this.municipioAtualNome,
    this.estadoAtualSigla,
    required this.lotacaoInterestadual,
    this.ocultarNoMapa,
    required this.isEmbaixador,
    this.postoGraduacaoId,
    this.postoGraduacaoNome,
    this.tipoPermuta,
    this.forcaSigla,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      forcaId: json['forca_id'],
      nome: json['nome'] ?? 'Usuário',
      email: json['email'],
      idFuncional: json['id_funcional'],
      qso: json['qso'],
      antiguidade: json['antiguidade'],
      unidadeAtualNome: json['unidade_atual_nome'],
      municipioAtualNome: json['municipio_atual_nome'],
      estadoAtualSigla: json['estado_atual_sigla'],
      lotacaoInterestadual: json['lotacao_interestadual'] == 1,
      ocultarNoMapa: json['ocultar_no_mapa'] == 1,
      isEmbaixador: json['embaixador'] == 1,
      postoGraduacaoId: json['posto_graduacao_id'],
      postoGraduacaoNome: json['posto_graduacao_nome'],
      tipoPermuta: json['forca_tipo_permuta'],
      forcaSigla: json['forca_sigla'],
    );
  }
}