import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/map_member_location.dart';
import '../models/map_point.dart';
import '../models/patrol_location.dart';
import '../providers/mapa_tatico_provider.dart';
import '../utils/mapa_tatico_map_styles.dart';
import '../utils/mapa_tatico_marker_utils.dart';
import '../utils/mapa_tatico_viewport_utils.dart';
import 'mapa_tatico_legend_widget.dart';
import 'mapa_tatico_marker_icon.dart';

/// Limite acima do qual marcadores usam widget simplificado (menos layout/paint).
const _kLightweightMarkerThreshold = 1500;

class MapaTaticoMapWidget extends StatefulWidget {
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
  State<MapaTaticoMapWidget> createState() => _MapaTaticoMapWidgetState();
}

class _MapaTaticoMapWidgetState extends State<MapaTaticoMapWidget> {
  LatLngBounds? _viewportBounds;
  List<Marker> _clusterMarkers = const [];
  List<MapPoint>? _lastBuiltPoints;
  LatLngBounds? _lastBuiltBounds;
  StreamSubscription<MapEvent>? _mapEventSub;
  Timer? _viewportDebounce;

  @override
  void initState() {
    super.initState();
    _mapEventSub = widget.mapController.mapEventStream.listen(_onMapEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshViewportBounds());
  }

  @override
  void didUpdateWidget(covariant MapaTaticoMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.points, widget.points)) {
      _rebuildClusterMarkers(force: true);
    }
  }

  @override
  void dispose() {
    _viewportDebounce?.cancel();
    _mapEventSub?.cancel();
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMove) {
      _scheduleViewportRefresh();
    } else if (event is MapEventMoveEnd ||
        event is MapEventFlingAnimationEnd ||
        event is MapEventDoubleTapZoomEnd ||
        event is MapEventRotateEnd) {
      _refreshViewportBounds();
    }
  }

  void _scheduleViewportRefresh() {
    _viewportDebounce?.cancel();
    _viewportDebounce = Timer(const Duration(milliseconds: 180), _refreshViewportBounds);
  }

  void _refreshViewportBounds() {
    if (!mounted) return;
    try {
      final bounds = widget.mapController.camera.visibleBounds;
      if (_viewportBounds == bounds) return;
      setState(() {
        _viewportBounds = bounds;
        _rebuildClusterMarkers(force: true);
      });
    } catch (_) {}
  }

  void _rebuildClusterMarkers({bool force = false}) {
    final bounds = _viewportBounds;
    final visiblePoints = bounds == null
        ? widget.points
        : filterPointsInBounds(widget.points, bounds);

    if (!force &&
        identical(_lastBuiltPoints, widget.points) &&
        _lastBuiltBounds == bounds &&
        _clusterMarkers.isNotEmpty) {
      return;
    }

    final lightweight = visiblePoints.length >= _kLightweightMarkerThreshold;

    _clusterMarkers = visiblePoints.map((p) {
      final expiringSoon = !lightweight && isPointExpiringSoon(p);
      final size = expiringSoon ? 48.0 : 40.0;
      return Marker(
        key: ValueKey(p.id),
        point: LatLng(p.lat, p.lng),
        width: lightweight ? 32 : size,
        height: lightweight ? 32 : size,
        child: lightweight
            ? GestureDetector(
                onTap: () => widget.onPointTap(p),
                child: _LightweightMarkerDot(color: markerColorForPointType(p)),
              )
            : GestureDetector(
                onTap: () => widget.onPointTap(p),
                child: MapaTaticoMarkerIcon(
                  point: p,
                  expiringSoon: expiringSoon,
                  currentUserId: context.read<MapaTaticoProvider>().currentUserId,
                ),
              ),
      );
    }).toList();

    _lastBuiltPoints = widget.points;
    _lastBuiltBounds = bounds;
  }

  @override
  Widget build(BuildContext context) {
    if (_clusterMarkers.isEmpty && widget.points.isNotEmpty) {
      _rebuildClusterMarkers(force: true);
    }

    return Stack(
      children: [
        RepaintBoundary(
          child: Selector<MapaTaticoProvider, MapaTaticoTileStyle>(
            selector: (_, p) => p.tileStyle,
            builder: (context, tileStyle, _) {
              return FlutterMap(
                mapController: widget.mapController,
                options: MapOptions(
                  initialCenter: const LatLng(-14.2350, -51.9253),
                  initialZoom: 4.5,
                  minZoom: 3,
                  maxZoom: 18,
                  onLongPress: (_, point) => widget.onLongPress(point),
                  onMapReady: _refreshViewportBounds,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: tileStyle.urlTemplate,
                    subdomains: tileStyle.subdomains,
                  ),
                  if (widget.routePoints.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: widget.routePoints,
                          color: Colors.blueAccent,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  _OperationalAlertCircle(mapType: widget.mapType),
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: _clusterRadiusFor(widget.points.length),
                      size: const Size(48, 48),
                      markers: _clusterMarkers,
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
                  const _UserAndTeamMarkers(),
                ],
              );
            },
          ),
        ),
        MapaTaticoLegendWidget(mapType: widget.mapType),
        Selector<MapaTaticoProvider, bool>(
          selector: (_, p) => p.isLoading,
          builder: (context, isLoading, _) {
            if (!isLoading) return const SizedBox.shrink();
            return Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Selector<MapaTaticoProvider, MapaTaticoTileStyle>(
            selector: (_, p) => p.tileStyle,
            builder: (context, tileStyle, _) {
              final provider = context.read<MapaTaticoProvider>();
              return Card(
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
                              if (tileStyle == s) const Icon(Icons.check, size: 18),
                              if (tileStyle == s) const SizedBox(width: 8),
                              Text(s.label),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
        ),
        _NavigationRecenterBridge(
          enabled: widget.navigationModeEnabled,
          lastCenteredPosition: widget.lastCenteredPosition,
          onRecenter: widget.onNavigationRecenter,
        ),
      ],
    );
  }

  int _clusterRadiusFor(int totalPoints) {
    if (totalPoints >= 5000) return 120;
    if (totalPoints >= 2000) return 100;
    return 80;
  }
}

class _NavigationRecenterBridge extends StatelessWidget {
  final bool enabled;
  final LatLng? lastCenteredPosition;
  final ValueChanged<LatLng> onRecenter;

  const _NavigationRecenterBridge({
    required this.enabled,
    required this.lastCenteredPosition,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();

    return Selector<MapaTaticoProvider, PatrolLocation?>(
      selector: (_, p) => p.currentPosition,
      builder: (context, position, _) {
        if (position == null) return const SizedBox.shrink();
        final currentLatLng = LatLng(position.latitude, position.longitude);
        final shouldRecenter = lastCenteredPosition == null ||
            const Distance().as(LengthUnit.Meter, lastCenteredPosition!, currentLatLng) > 7;
        if (shouldRecenter) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onRecenter(currentLatLng));
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _OperationalAlertCircle extends StatelessWidget {
  final String mapType;

  const _OperationalAlertCircle({required this.mapType});

  @override
  Widget build(BuildContext context) {
    if (mapType != 'OPERATIONAL') return const SizedBox.shrink();

    return Selector<MapaTaticoProvider, (PatrolLocation?, double, bool)>(
      selector: (_, p) => (p.currentPosition, p.alertRadiusMeters, p.hasNearbyPointInAlertRadius),
      builder: (context, data, _) {
        final (position, radius, hasNearby) = data;
        if (position == null) return const SizedBox.shrink();
        final center = LatLng(position.latitude, position.longitude);
        return CircleLayer(
          circles: [
            CircleMarker(
              point: center,
              radius: radius,
              useRadiusInMeter: true,
              color: hasNearby ? Colors.red.withAlpha(55) : Colors.lightBlueAccent.withAlpha(55),
              borderStrokeWidth: 2,
              borderColor: hasNearby ? Colors.red.withAlpha(150) : Colors.lightBlue.withAlpha(150),
            ),
          ],
        );
      },
    );
  }
}

class _UserAndTeamMarkers extends StatelessWidget {
  const _UserAndTeamMarkers();

  @override
  Widget build(BuildContext context) {
    return Selector<MapaTaticoProvider, (PatrolLocation?, List<MapMemberLocation>)>(
      selector: (_, p) => (p.currentPosition, p.teamLocations),
      builder: (context, data, _) {
        final (position, team) = data;
        return MarkerLayer(
          markers: [
            if (position != null)
              Marker(
                point: LatLng(position.latitude, position.longitude),
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
            ...team.map(_teamMarker),
          ],
        );
      },
    );
  }

  static Marker _teamMarker(MapMemberLocation member) {
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

class _LightweightMarkerDot extends StatelessWidget {
  final Color color;

  const _LightweightMarkerDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}
