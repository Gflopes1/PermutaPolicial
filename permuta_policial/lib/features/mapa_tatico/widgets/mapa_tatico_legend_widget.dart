import 'package:flutter/material.dart';

import '../models/mapa_tatico_filters.dart';
import '../utils/mapa_tatico_marker_utils.dart';

class MapaTaticoLegendWidget extends StatefulWidget {
  final String mapType;

  const MapaTaticoLegendWidget({super.key, required this.mapType});

  @override
  State<MapaTaticoLegendWidget> createState() => _MapaTaticoLegendWidgetState();
}

class _MapaTaticoLegendWidgetState extends State<MapaTaticoLegendWidget> {
  bool _expanded = false;

  String get _title {
    switch (widget.mapType) {
      case 'LOGISTICS':
        return 'Legenda — Logística';
      case 'NATIONAL':
        return 'Legenda — Nacional';
      default:
        return 'Legenda — Operacional';
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = MapaTaticoFilters.typesForMapTab(widget.mapType);

    return Positioned(
      left: 8,
      bottom: 8,
      child: Card(
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.bottomLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.legend_toggle, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded ? Icons.expand_more : Icons.expand_less,
                        size: 16,
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 6),
                    ...types.map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: markerColorForType(type),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                markerEmojiForType(type),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(pointTypeLabel(type), style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
