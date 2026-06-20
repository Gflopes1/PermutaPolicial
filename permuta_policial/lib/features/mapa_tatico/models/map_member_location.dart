class MapMemberLocation {
  final int userId;
  final double lat;
  final double lng;
  final bool sharingEnabled;
  final DateTime updatedAt;
  final String? displayName;

  MapMemberLocation({
    required this.userId,
    required this.lat,
    required this.lng,
    required this.sharingEnabled,
    required this.updatedAt,
    this.displayName,
  });

  factory MapMemberLocation.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0;
    }

    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    return MapMemberLocation(
      userId: parseInt(json['user_id']),
      lat: parseDouble(json['lat']),
      lng: parseDouble(json['lng']),
      sharingEnabled: json['sharing_enabled'] == true || json['sharing_enabled'] == 1,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      displayName: json['display_name'] as String?,
    );
  }
}
