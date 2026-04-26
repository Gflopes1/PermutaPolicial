import '../models/patrol_location.dart';
import 'location_tracking_service.dart';

class UnsupportedLocationTrackingService implements LocationTrackingService {
  @override
  void dispose() {}

  @override
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return 0;
  }

  @override
  Future<bool> ensurePermission() async => false;

  @override
  Future<PatrolLocation?> getCurrentLocation() async => null;

  @override
  Stream<PatrolLocation> getLocationStream() => const Stream.empty();
}

LocationTrackingService createLocationTrackingServiceImpl() =>
    UnsupportedLocationTrackingService();
