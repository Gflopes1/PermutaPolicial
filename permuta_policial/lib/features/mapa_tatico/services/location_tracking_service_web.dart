import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' show Geolocator;
import 'package:web/web.dart' as web;

import '../models/patrol_location.dart';
import 'location_tracking_service.dart';

/// Implementação web usando a API nativa do navegador (navigator.geolocation).
///
/// O plugin geolocator na web usa a Permissions API para checar/pedir
/// permissão, o que em muitos navegadores NÃO dispara o prompt nativo.
/// O prompt só aparece de forma confiável ao chamar getCurrentPosition
/// diretamente — é isso que fazemos aqui.
class WebLocationTrackingService implements LocationTrackingService {
  bool get _isSecureContext => web.window.isSecureContext;

  bool _permissionGranted = false;
  int _lastErrorCode = 0;

  @override
  String get locationUnavailableMessage {
    if (!_isSecureContext) {
      return 'A localização no navegador só funciona com HTTPS. '
          'Acesse o site por https:// ou use o app no celular.';
    }
    if (_lastErrorCode == 1) {
      return 'Permissão de localização negada. Clique no ícone de cadeado '
          'na barra de endereço e permita a localização para este site.';
    }
    return 'Clique em "Ativar" e permita o acesso à localização quando o navegador solicitar.';
  }

  @override
  void dispose() {}

  @override
  void setBackgroundMode(bool enabled) {}

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

  /// Chama navigator.geolocation.getCurrentPosition diretamente.
  /// É a única forma garantida de disparar o prompt de permissão.
  Future<PatrolLocation?> _getNativePosition({int timeoutMs = 15000}) {
    final completer = Completer<PatrolLocation?>();

    void onSuccess(web.GeolocationPosition position) {
      _permissionGranted = true;
      _lastErrorCode = 0;
      debugPrint(
        '[MapaTatico/Web] Posição OK: '
        '${position.coords.latitude}, ${position.coords.longitude}',
      );
      if (!completer.isCompleted) {
        completer.complete(
          PatrolLocation(
            latitude: position.coords.latitude.toDouble(),
            longitude: position.coords.longitude.toDouble(),
          ),
        );
      }
    }

    void onError(web.GeolocationPositionError error) {
      _lastErrorCode = error.code;
      debugPrint(
        '[MapaTatico/Web] geolocation erro ${error.code}: ${error.message} '
        '(1=negado, 2=indisponível, 3=timeout)',
      );
      if (!completer.isCompleted) completer.complete(null);
    }

    try {
      web.window.navigator.geolocation.getCurrentPosition(
        onSuccess.toJS,
        onError.toJS,
        web.PositionOptions(
          enableHighAccuracy: true,
          timeout: timeoutMs,
          maximumAge: 5000,
        ),
      );
    } catch (e) {
      debugPrint('[MapaTatico/Web] navigator.geolocation falhou: $e');
      if (!completer.isCompleted) completer.complete(null);
    }

    return completer.future;
  }

  @override
  Future<bool> ensurePermission() async {
    if (!_isSecureContext) {
      debugPrint('[MapaTatico/Web] Contexto inseguro — geolocalização bloqueada');
      return false;
    }
    if (_permissionGranted) return true;

    final position = await _getNativePosition();
    return position != null;
  }

  @override
  Future<PatrolLocation?> getCurrentLocation() async {
    if (!_isSecureContext) return null;
    return _getNativePosition();
  }

  @override
  Stream<PatrolLocation> getLocationStream() {
    final controller = StreamController<PatrolLocation>();
    int? watchId;

    void onSuccess(web.GeolocationPosition position) {
      _permissionGranted = true;
      _lastErrorCode = 0;
      if (!controller.isClosed) {
        controller.add(
          PatrolLocation(
            latitude: position.coords.latitude.toDouble(),
            longitude: position.coords.longitude.toDouble(),
          ),
        );
      }
    }

    void onError(web.GeolocationPositionError error) {
      _lastErrorCode = error.code;
      debugPrint('[MapaTatico/Web] watchPosition erro ${error.code}: ${error.message}');
      // Permissão negada: encerra o stream para o app exibir o aviso
      if (error.code == 1 && !controller.isClosed) {
        controller.close();
      }
    }

    controller.onListen = () {
      if (!_isSecureContext) {
        controller.close();
        return;
      }
      try {
        watchId = web.window.navigator.geolocation.watchPosition(
          onSuccess.toJS,
          onError.toJS,
          web.PositionOptions(enableHighAccuracy: true, maximumAge: 5000),
        );
      } catch (e) {
        debugPrint('[MapaTatico/Web] watchPosition falhou: $e');
        controller.close();
      }
    };

    controller.onCancel = () {
      if (watchId != null) {
        try {
          web.window.navigator.geolocation.clearWatch(watchId!);
        } catch (_) {}
      }
    };

    return controller.stream;
  }
}

LocationTrackingService createLocationTrackingServiceImpl() =>
    WebLocationTrackingService();
