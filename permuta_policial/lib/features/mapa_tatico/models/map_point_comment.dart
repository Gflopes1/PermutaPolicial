// /lib/features/mapa_tatico/models/map_point_comment.dart

class MapPointComment {
  final int id;
  final int pointId;
  final int userId;
  final String text;
  final DateTime createdAt;
  final String? authorDisplayName;

  MapPointComment({
    required this.id,
    required this.pointId,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.authorDisplayName,
  });

  factory MapPointComment.fromJson(Map<String, dynamic> json) {
    return MapPointComment(
      id: json['id'] as int,
      pointId: json['point_id'] as int,
      userId: json['user_id'] as int,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorDisplayName: json['author_display_name'] as String?,
    );
  }
}
