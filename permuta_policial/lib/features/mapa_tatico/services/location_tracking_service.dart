import '../models/patrol_location.dart';
import 'location_tracking_service_stub.dart'
    if (dart.library.html) 'location_tracking_service_web.dart'
    if (dart.library.io) 'location_tracking_service_mobile.dart';

abstract class LocationTrackingService {
  /// Mensagem amigável quando a localização não está disponível.
  String get locationUnavailableMessage;

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

  /// Android: ativa serviço em primeiro plano para rastrear em background.
  void setBackgroundMode(bool enabled) {}
}

LocationTrackingService createLocationTrackingService() =>
    createLocationTrackingServiceImpl();
