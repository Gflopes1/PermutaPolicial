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
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    return MapPointComment(
      id: parseInt(json['id']),
      pointId: parseInt(json['point_id']),
      userId: parseInt(json['user_id']),
      text: json['text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorDisplayName: json['author_display_name'] as String?,
    );
  }
}
