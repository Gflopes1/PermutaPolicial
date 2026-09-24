import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/map_point.dart';

/// Expande os bounds visíveis para incluir marcadores próximos à borda.
LatLngBounds expandBounds(LatLngBounds bounds, {double paddingFactor = 0.12}) {
  final latSpan = (bounds.north - bounds.south).abs();
  final lngSpan = (bounds.east - bounds.west).abs();
  return LatLngBounds(
    LatLng(bounds.south - latSpan * paddingFactor, bounds.west - lngSpan * paddingFactor),
    LatLng(bounds.north + latSpan * paddingFactor, bounds.east + lngSpan * paddingFactor),
  );
}

/// Filtra pontos dentro dos bounds (com padding opcional).
List<MapPoint> filterPointsInBounds(
  List<MapPoint> points,
  LatLngBounds bounds, {
  double paddingFactor = 0.12,
}) {
  if (points.isEmpty) return const [];
  final padded = expandBounds(bounds, paddingFactor: paddingFactor);
  return points.where((p) => padded.contains(LatLng(p.lat, p.lng))).toList();
}
