// /lib/features/mapa_tatico/models/map_point_visit.dart

class MapPointVisit {
  final int id;
  final int pointId;
  final int userId;
  final DateTime visitedAt;
  final String? userDisplayName;

  MapPointVisit({
    required this.id,
    required this.pointId,
    required this.userId,
    required this.visitedAt,
    this.userDisplayName,
  });

  factory MapPointVisit.fromJson(Map<String, dynamic> json) {
    return MapPointVisit(
      id: json['id'] as int,
      pointId: json['point_id'] as int,
      userId: json['user_id'] as int,
      visitedAt: DateTime.parse(json['visited_at'] as String),
      userDisplayName: json['user_display_name'] as String?,
    );
  }
}
