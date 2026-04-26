import 'package:geolocator/geolocator.dart';

import '../models/patrol_location.dart';
import 'location_tracking_service.dart';

class MobileLocationTrackingService implements LocationTrackingService {
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

    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  @override
  Future<PatrolLocation?> getCurrentLocation() async {
    final hasPermission = await ensurePermission();
    if (!hasPermission) return null;

    final position = await Geolocator.getCurrentPosition();
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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
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
