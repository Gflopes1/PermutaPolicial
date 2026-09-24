class AddressSearchResult {
  final String displayName;
  final double lat;
  final double lng;

  AddressSearchResult({
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  factory AddressSearchResult.fromJson(Map<String, dynamic> json) {
    return AddressSearchResult(
      displayName: json['display_name'] as String? ?? 'Endereço',
      lat: double.tryParse(json['lat']?.toString() ?? '') ?? 0,
      lng: double.tryParse(json['lon']?.toString() ?? '') ?? 0,
    );
  }
}
