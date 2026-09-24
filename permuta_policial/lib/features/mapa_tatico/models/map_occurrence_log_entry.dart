class MapOccurrenceLogEntry {
  final int id;
  final int pointId;
  final int authorId;
  final String entryType;
  final String narrative;
  final String? status;
  final DateTime occurredAt;
  final DateTime createdAt;
  final String? authorDisplayName;

  MapOccurrenceLogEntry({
    required this.id,
    required this.pointId,
    required this.authorId,
    required this.entryType,
    required this.narrative,
    this.status,
    required this.occurredAt,
    required this.createdAt,
    this.authorDisplayName,
  });

  factory MapOccurrenceLogEntry.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return MapOccurrenceLogEntry(
      id: parseInt(json['id']),
      pointId: parseInt(json['point_id']),
      authorId: parseInt(json['author_id']),
      entryType: json['entry_type'] as String? ?? 'ATUALIZACAO',
      narrative: json['narrative'] as String,
      status: json['status'] as String?,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      authorDisplayName: json['author_display_name'] as String?,
    );
  }
}
