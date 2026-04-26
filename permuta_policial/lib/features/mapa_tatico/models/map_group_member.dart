class MapGroupMember {
  final int id;
  final int groupId;
  final int userId;
  final String role;
  final String? nomeDeGuerra;
  final bool isMuted;
  final String nome;
  final String? email;

  MapGroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    this.nomeDeGuerra,
    required this.isMuted,
    required this.nome,
    this.email,
  });

  factory MapGroupMember.fromJson(Map<String, dynamic> json) {
    return MapGroupMember(
      id: json['id'] as int,
      groupId: json['group_id'] as int,
      userId: json['user_id'] as int,
      role: json['role'] as String,
      nomeDeGuerra: json['nome_de_guerra'] as String?,
      isMuted: json['is_muted'] == true || json['is_muted'] == 1,
      nome: json['nome'] as String? ?? 'Usuário',
      email: json['email'] as String?,
    );
  }

  bool get isModerator => role == 'MODERATOR';
  String get displayName => (nomeDeGuerra != null && nomeDeGuerra!.trim().isNotEmpty)
      ? nomeDeGuerra!.trim()
      : nome;
}
