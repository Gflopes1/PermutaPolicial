import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/map_member_location.dart';
import '../models/map_point.dart';
import '../providers/mapa_tatico_provider.dart';
import '../utils/mapa_tatico_map_styles.dart';
import '../utils/mapa_tatico_marker_utils.dart';
import 'mapa_tatico_legend_widget.dart';
import 'mapa_tatico_marker_icon.dart';

class MapaTaticoMapWidget extends StatelessWidget {
  final MapController mapController;
  final List<MapPoint> points;
  final String mapType;
  final bool navigationModeEnabled;
  final LatLng? lastCenteredPosition;
  final ValueChanged<LatLng> onNavigationRecenter;
  final ValueChanged<MapPoint> onPointTap;
  final void Function(LatLng position) onLongPress;
  final List<LatLng> routePoints;

  const MapaTaticoMapWidget({
    super.key,
    required this.mapController,
    required this.points,
    required this.mapType,
    required this.navigationModeEnabled,
    required this.lastCenteredPosition,
    required this.onNavigationRecenter,
    required this.onPointTap,
    required this.onLongPress,
    this.routePoints = const [],
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MapaTaticoProvider>();
    final currentLatLng = provider.currentPosition != null
        ? LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude)
        : null;

    if (navigationModeEnabled && currentLatLng != null) {
      final shouldRecenter = lastCenteredPosition == null ||
          const Distance().as(LengthUnit.Meter, lastCenteredPosition!, currentLatLng) > 7;
      if (shouldRecenter) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onNavigationRecenter(currentLatLng);
        });
      }
    }

    final markers = points.map((p) {
      final expiringSoon = isPointExpiringSoon(p);
      return Marker(
        key: ValueKey(p.id),
        point: LatLng(p.lat, p.lng),
        width: expiringSoon ? 48 : 40,
        height: expiringSoon ? 48 : 40,
        child: GestureDetector(
          onTap: () => onPointTap(p),
          child: MapaTaticoMarkerIcon(point: p, expiringSoon: expiringSoon),
        ),
      );
    }).toList();

    final tileStyle = provider.tileStyle;

    return Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: const LatLng(-14.2350, -51.9253),
              initialZoom: 4.5,
              minZoom: 3,
              maxZoom: 18,
              onLongPress: (_, point) => onLongPress(point),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: tileStyle.urlTemplate,
                subdomains: tileStyle.subdomains,
              ),
              if (routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: Colors.blueAccent,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              if (currentLatLng != null && mapType == 'OPERATIONAL')
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: currentLatLng,
                      radius: provider.alertRadiusMeters,
                      useRadiusInMeter: true,
                      color: provider.hasNearbyPointInAlertRadius
                          ? Colors.red.withAlpha(55)
                          : Colors.lightBlueAccent.withAlpha(55),
                      borderStrokeWidth: 2,
                      borderColor: provider.hasNearbyPointInAlertRadius
                          ? Colors.red.withAlpha(150)
                          : Colors.lightBlue.withAlpha(150),
                    ),
                  ],
                ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 80,
                  size: const Size(48, 48),
                  markers: markers,
                  builder: (context, clusterMarkers) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${clusterMarkers.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              MarkerLayer(
              markers: [
                if (currentLatLng != null)
                  Marker(
                    point: currentLatLng,
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(child: Text('🚓', style: TextStyle(fontSize: 16))),
                    ),
                  ),
                ...provider.teamLocations.map((m) => _teamMarker(m)),
              ],
            ),
            ],
          ),
          MapaTaticoLegendWidget(mapType: mapType),
          if (provider.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            right: 8,
            top: 8,
            child: Card(
              child: PopupMenuButton<MapaTaticoTileStyle>(
                icon: const Icon(Icons.layers_outlined),
                tooltip: 'Estilo do mapa',
                onSelected: provider.setTileStyle,
                itemBuilder: (_) => MapaTaticoTileStyle.values
                    .map(
                      (s) => PopupMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            if (provider.tileStyle == s) const Icon(Icons.check, size: 18),
                            if (provider.tileStyle == s) const SizedBox(width: 8),
                            Text(s.label),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
    );
  }

  Marker _teamMarker(MapMemberLocation member) {
    final age = DateTime.now().difference(member.updatedAt);
    final label = member.displayName?.isNotEmpty == true
        ? member.displayName!.substring(0, 1).toUpperCase()
        : '?';
    return Marker(
      point: LatLng(member.lat, member.lng),
      width: 44,
      height: 44,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.teal,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              age.inMinutes < 1 ? 'agora' : '${age.inMinutes}m',
              style: const TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}
