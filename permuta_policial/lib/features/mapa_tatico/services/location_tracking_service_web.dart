import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;

import '../models/patrol_location.dart';
import 'location_tracking_service.dart';

class WebLocationTrackingService implements LocationTrackingService {
  final StreamController<PatrolLocation> _controller =
      StreamController<PatrolLocation>.broadcast();
  Timer? _pollingTimer;
  bool _streamStarted = false;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _controller.close();
  }

  @override
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const earthRadiusMeters = 6371000.0;
    final startLatRad = _toRadians(startLatitude);
    final endLatRad = _toRadians(endLatitude);
    final deltaLat = _toRadians(endLatitude - startLatitude);
    final deltaLng = _toRadians(endLongitude - startLongitude);

    final a = _sinSquared(deltaLat / 2) +
        _cos(startLatRad) *
            _cos(endLatRad) *
            _sinSquared(deltaLng / 2);
    final c = 2 * _atan2Sqrt(a, 1 - a);
    return earthRadiusMeters * c;
  }

  @override
  Future<bool> ensurePermission() async {
    if (html.window.isSecureContext != true) {
      return false;
    }
    final location = await getCurrentLocation();
    return location != null;
  }

  @override
  Future<PatrolLocation?> getCurrentLocation() {
    if (html.window.isSecureContext != true) {
      return Future.value(null);
    }
    return html.window.navigator.geolocation
        .getCurrentPosition(
          enableHighAccuracy: true,
          timeout: const Duration(seconds: 10),
          maximumAge: Duration.zero,
        )
        .then(
      (position) => PatrolLocation(
        latitude: (position.coords?.latitude ?? 0).toDouble(),
        longitude: (position.coords?.longitude ?? 0).toDouble(),
      ),
      onError: (_) => null,
    );
  }

  @override
  Stream<PatrolLocation> getLocationStream() {
    if (!_streamStarted) {
      _streamStarted = true;
      _emitCurrentLocation();
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _emitCurrentLocation();
      });
    }
    return _controller.stream;
  }

  Future<void> _emitCurrentLocation() async {
    final current = await getCurrentLocation();
    if (current == null) return;
    if (current.latitude == 0 && current.longitude == 0) return;
    _controller.add(current);
  }

  double _toRadians(double degrees) => degrees * 0.017453292519943295;
  double _sinSquared(double value) {
    final sine = math.sin(value);
    return sine * sine;
  }

  double _cos(double value) => math.cos(value);

  double _atan2Sqrt(double a, double b) =>
      math.atan2(math.sqrt(a), math.sqrt(b));
}

LocationTrackingService createLocationTrackingServiceImpl() =>
    WebLocationTrackingService();
