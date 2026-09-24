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
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return MapGroupMember(
      id: parseInt(json['id']),
      groupId: parseInt(json['group_id']),
      userId: parseInt(json['user_id']),
      role: json['role'] as String? ?? 'MEMBER',
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
