import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../models/patrol_location.dart';
import 'location_tracking_service.dart';

class MobileLocationTrackingService implements LocationTrackingService {
  bool _backgroundMode = false;

  @override
  String get locationUnavailableMessage =>
      'Ative o GPS e permita o acesso à localização nas configurações do aparelho.';

  @override
  void setBackgroundMode(bool enabled) {
    _backgroundMode = enabled;
  }

  @override
  void dispose() {}

  @override
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  @override
  Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (_backgroundMode && permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse) {
        permission = await Geolocator.requestPermission();
      }
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  LocationSettings _locationSettings() {
    if (_backgroundMode && Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'Compartilhando posição com o grupo no mapa tático',
          notificationTitle: 'Permuta Policial — Mapa Tático',
          enableWakeLock: true,
        ),
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);
  }

  @override
  Future<PatrolLocation?> getCurrentLocation() async {
    final hasPermission = await ensurePermission();
    if (!hasPermission) return null;

    final position = await Geolocator.getCurrentPosition(
      locationSettings: _locationSettings(),
    );
    return PatrolLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  Stream<PatrolLocation> getLocationStream() async* {
    final hasPermission = await ensurePermission();
    if (!hasPermission) return;

    yield* Geolocator.getPositionStream(
      locationSettings: _locationSettings(),
    ).map(
      (position) => PatrolLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
    );
  }
}

LocationTrackingService createLocationTrackingServiceImpl() =>
    MobileLocationTrackingService();
