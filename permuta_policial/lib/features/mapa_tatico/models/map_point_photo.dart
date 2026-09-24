class MapPointPhoto {
  final int id;
  final String url;
  final String? caption;
  final int orderIndex;

  MapPointPhoto({
    required this.id,
    required this.url,
    this.caption,
    required this.orderIndex,
  });

  factory MapPointPhoto.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return MapPointPhoto(
      id: parseInt(json['id']),
      url: json['url']?.toString() ?? '',
      caption: json['caption'] as String?,
      orderIndex: parseInt(json['order_index'] ?? json['orderIndex'] ?? 0),
    );
  }
}
