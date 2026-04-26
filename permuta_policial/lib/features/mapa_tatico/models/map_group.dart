// /lib/features/mapa_tatico/models/map_group.dart

class MapGroup {
  final int id;
  final String name;
  final int creatorId;
  final String? creatorNome;
  final String? role;
  final String? nomeDeGuerra;
  final bool isMuted;

  MapGroup({
    required this.id,
    required this.name,
    required this.creatorId,
    this.creatorNome,
    this.role,
    this.nomeDeGuerra,
    this.isMuted = false,
  });

  factory MapGroup.fromJson(Map<String, dynamic> json) {
    return MapGroup(
      id: json['id'] as int,
      name: json['name'] as String,
      creatorId: json['creator_id'] as int,
      creatorNome: json['creator_nome'] as String?,
      role: json['role'] as String?,
      nomeDeGuerra: json['nome_de_guerra'] as String?,
      isMuted: json['is_muted'] == true || json['is_muted'] == 1,
    );
  }

  bool get isModerator => role == 'MODERATOR';
}
