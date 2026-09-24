import 'package:flutter/material.dart';

import '../models/map_point.dart';
import '../utils/mapa_tatico_marker_utils.dart';
import '../utils/mapa_tatico_type_constants.dart';

/// Marcador circular com emoji ou cruz médica.
class MapaTaticoMarkerIcon extends StatelessWidget {
  final MapPoint point;
  final bool expiringSoon;
  final int? currentUserId;

  const MapaTaticoMarkerIcon({
    super.key,
    required this.point,
    this.expiringSoon = false,
    this.currentUserId,
  });

  bool get _showPrivateLock =>
      point.isPrivate && currentUserId != null && point.creatorId == currentUserId;

  bool get _highRiskSuspect => point.type == 'suspeito' && (point.suspectProfile?.isHighRisk ?? false);

  @override
  Widget build(BuildContext context) {
    final size = (expiringSoon || _highRiskSuspect) ? 48.0 : 40.0;
    final health = isHealthPointType(point.type);
    final pulseColor = _highRiskSuspect ? Colors.red : Colors.orange;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: health ? _healthBackground(point.type) : markerColorForPointType(point),
            shape: BoxShape.circle,
            border: Border.all(
              color: expiringSoon || _highRiskSuspect ? pulseColor : Colors.white,
              width: expiringSoon || _highRiskSuspect ? 3 : 2,
            ),
            boxShadow: expiringSoon || _highRiskSuspect
                ? [
                    BoxShadow(
                      color: pulseColor.withAlpha(120),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: health
              ? _healthCross(point.type)
              : _highRiskSuspect
                  ? const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18)
                  : Text(markerEmojiForPointType(point), style: const TextStyle(fontSize: 16)),
        ),
        if (_showPrivateLock)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(180),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white70, width: 1),
              ),
              child: const Icon(Icons.lock, size: 10, color: Colors.white),
            ),
          ),
      ],
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
