// /lib/features/mapa_tatico/models/map_group.dart

class MapGroup {
  final int id;
  final String name;
  final int creatorId;
  final String? creatorNome;
  final String? role;
  final String? nomeDeGuerra;
  final bool isMuted;
  final bool isGlobal;

  MapGroup({
    required this.id,
    required this.name,
    required this.creatorId,
    this.creatorNome,
    this.role,
    this.nomeDeGuerra,
    this.isMuted = false,
    this.isGlobal = false,
  });

  factory MapGroup.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return MapGroup(
      id: parseInt(json['id']),
      name: json['name'] as String? ?? '',
      creatorId: parseInt(json['creator_id']),
      creatorNome: json['creator_nome'] as String?,
      role: json['role'] as String?,
      nomeDeGuerra: json['nome_de_guerra'] as String?,
      isMuted: json['is_muted'] == true || json['is_muted'] == 1,
      isGlobal: json['is_global'] == true || json['is_global'] == 1,
    );
  }

  bool get isModerator => role == 'MODERATOR';
}
