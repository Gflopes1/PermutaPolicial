import 'package:flutter/material.dart';

import '../models/map_point.dart';
import '../utils/mapa_tatico_marker_utils.dart';
import '../utils/mapa_tatico_type_constants.dart';

/// Marcador circular com emoji ou cruz médica.
class MapaTaticoMarkerIcon extends StatelessWidget {
  final MapPoint point;
  final bool expiringSoon;

  const MapaTaticoMarkerIcon({
    super.key,
    required this.point,
    this.expiringSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = expiringSoon ? 48.0 : 40.0;
    final health = isHealthPointType(point.type);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: health ? _healthBackground(point.type) : markerColorForPointType(point),
        shape: BoxShape.circle,
        border: Border.all(
          color: expiringSoon ? Colors.orange : Colors.white,
          width: expiringSoon ? 3 : 2,
        ),
        boxShadow: expiringSoon
            ? [
                BoxShadow(
                  color: Colors.orange.withAlpha(120),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: health ? _healthCross(point.type) : Text(markerEmojiForPointType(point), style: const TextStyle(fontSize: 16)),
    );
  }

  Color _healthBackground(String type) {
    if (type == 'hospital_trauma') return Colors.red.shade700;
    return Colors.white;
  }

  Widget _healthCross(String type) {
    final crossColor = type == 'hospital_trauma' ? Colors.white : Colors.red.shade700;
    return Icon(Icons.add, color: crossColor, size: 22);
  }
}
