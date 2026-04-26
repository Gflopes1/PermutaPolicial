import '../models/patrol_location.dart';
import 'location_tracking_service_stub.dart'
    if (dart.library.html) 'location_tracking_service_web.dart'
    if (dart.library.io) 'location_tracking_service_mobile.dart';

abstract class LocationTrackingService {
  Future<PatrolLocation?> getCurrentLocation();
  Stream<PatrolLocation> getLocationStream();
  Future<bool> ensurePermission();
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  );
  void dispose();
}

LocationTrackingService createLocationTrackingService() =>
    createLocationTrackingServiceImpl();
