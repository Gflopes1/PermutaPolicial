// /lib/features/mapa_tatico/providers/mapa_tatico_provider.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/repositories/mapa_tatico_repository.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/utils/error_handler.dart';
import '../models/group_invite.dart';
import '../models/map_group.dart';
import '../models/map_group_member.dart';
import '../models/map_point.dart';
import '../models/map_point_comment.dart';
import '../models/map_point_visit.dart';
import '../models/mapa_tatico_filters.dart';
import '../models/address_search_result.dart';
import '../models/map_member_location.dart';
import '../models/patrol_location.dart';
import '../services/location_tracking_service.dart';
import '../utils/mapa_tatico_map_styles.dart';
import '../utils/mapa_tatico_type_constants.dart';

class MapaTaticoProvider with ChangeNotifier {
  static const _prefAlertRadius = 'mapa_tatico_alert_radius';
  static const _prefTileStyle = 'mapa_tatico_tile_style';

  final MapaTaticoRepository _repository;
  final SocketService _socketService;
  final LocationTrackingService _locationService = createLocationTrackingService();

  MapaTaticoProvider(this._repository, this._socketService);

  List<MapGroup> _groups = [];
  MapGroup? _activeGroup;
  List<MapPoint> _pointsOperational = [];
  List<MapPoint> _pointsLogistics = [];
  List<MapPoint> _pointsShared = [];
  List<MapPoint> _pointsNational = [];
  List<GroupInvite> _pendingInvites = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isMuted = false;
  double _alertRadiusMeters = 200;
  PatrolLocation? _currentPosition;
  DateTime? _lastPositionAt;
  bool _hasNearbyPointInAlertRadius = false;
  bool _photoUploadEnabled = true;
  StreamSubscription<PatrolLocation>? _positionSubscription;
  Timer? _proximityCheckTimer;
  final Set<int> _alertedPointIds = {};
  bool _isAppInForeground = true;
  bool _isLocationStreamActive = false;
  bool _isRefreshingPosition = false;

  MapaTaticoFilters _filtersOperational = const MapaTaticoFilters();
  MapaTaticoFilters _filtersLogistics = const MapaTaticoFilters();
  MapaTaticoTileStyle _tileStyle = MapaTaticoTileStyle.standard;

  int? _joinedGroupId;
  bool _socketListenersSetup = false;
  bool _realtimeReady = false;
  int? _currentUserId;

  final Map<int, List<MapPointComment>> _recentCommentsByPointId = {};
  List<MapMemberLocation> _teamLocations = [];
  bool _sharingLocationEnabled = false;
  DateTime? _lastPointsSyncAt;
  Timer? _teamLocationSyncTimer;
  List<LatLng> _navigationRoute = [];

  List<MapGroup> get groups => _groups;
  MapGroup? get activeGroup => _activeGroup;
  MapGroup? get globalGroup {
    for (final g in _groups) {
      if (g.isGlobal) return g;
    }
    return null;
  }

  List<MapGroup> get privateGroups => _groups.where((g) => !g.isGlobal).toList();

  List<MapPoint> get pointsOperational =>
      _filteredPoints([..._pointsOperational, ..._pointsShared], _filtersOperational);
  List<MapPoint> get pointsLogistics =>
      _filteredPoints([..._pointsLogistics, ..._pointsShared], _filtersLogistics);
  List<MapPoint> get pointsNational => _filteredPoints(_pointsNational, const MapaTaticoFilters());
  List<MapPoint> get allPoints => [...pointsOperational, ...pointsLogistics, ...pointsNational];
  List<GroupInvite> get pendingInvites => _pendingInvites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isMuted => _isMuted;
  double get alertRadiusMeters => _alertRadiusMeters;
  PatrolLocation? get currentPosition => _currentPosition;
  DateTime? get lastPositionAt => _lastPositionAt;
  bool get hasNearbyPointInAlertRadius => _hasNearbyPointInAlertRadius;
  bool get photoUploadEnabled => _photoUploadEnabled;
  MapaTaticoFilters get filtersOperational => _filtersOperational;
  MapaTaticoFilters get filtersLogistics => _filtersLogistics;
  MapaTaticoTileStyle get tileStyle => _tileStyle;
  bool get realtimeReady => _realtimeReady;
  List<MapMemberLocation> get teamLocations => _teamLocations;
  bool get sharingLocationEnabled => _sharingLocationEnabled;
  List<LatLng> get navigationRoute => _navigationRoute;
  String get locationUnavailableMessage => _locationService.locationUnavailableMessage;

  void setNavigationRoute(List<LatLng> points) {
    _navigationRoute = points;
    notifyListeners();
  }

  void clearNavigationRoute() {
    _navigationRoute = [];
    notifyListeners();
  }

  void Function(MapPoint point)? onProximityAlert;
  void Function(MapPoint point, MapPointComment comment)? onPointCommentAdded;

  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _alertRadiusMeters = prefs.getDouble(_prefAlertRadius) ?? 200;
      _tileStyle = MapaTaticoTileStyleX.fromStorage(prefs.getString(_prefTileStyle));
      notifyListeners();
    } catch (_) {}
  }

  void setCurrentUserId(int? userId) {
    _currentUserId = userId;
  }

  void _setError(dynamic e) {
    _errorMessage = ErrorHandler.getErrorMessage(e);
  }

  Future<void> initializeRealtime() async {
    try {
      await _socketService.connect();
      if (!_socketListenersSetup) {
        _setupSocketListeners();
        _socketListenersSetup = true;
      }
      _realtimeReady = true;
      await _joinActiveGroupRoom();
    } catch (e) {
      _realtimeReady = false;
      debugPrint('Mapa tático: falha ao conectar tempo real: $e');
    }
  }

  void _setupSocketListeners() {
    _socketService.onMapaTaticoPointCreated((data) {
      final pointJson = data['point'];
      if (pointJson is! Map) return;
      final point = MapPoint.fromJson(Map<String, dynamic>.from(pointJson));
      if (!_shouldTrackPoint(point)) return;
      _upsertPoint(point);
      notifyListeners();
    });

    _socketService.onMapaTaticoPointUpdated((data) {
      final pointJson = data['point'];
      if (pointJson is! Map) return;
      final point = MapPoint.fromJson(Map<String, dynamic>.from(pointJson));
      if (!_shouldTrackPoint(point)) return;
      _upsertPoint(point);
      notifyListeners();
    });

    _socketService.onMapaTaticoPointDeleted((data) {
      final pointIdRaw = data['point_id'];
      final pointId = pointIdRaw is int
          ? pointIdRaw
          : (pointIdRaw is num ? pointIdRaw.toInt() : int.tryParse('$pointIdRaw'));
      if (pointId == null) return;
      _removePoint(pointId);
      notifyListeners();
    });

    _socketService.onMapaTaticoCommentAdded((data) {
      final pointIdRaw = data['point_id'];
      final commentJson = data['comment'];
      if (pointIdRaw == null || commentJson is! Map) return;
      final pointId = pointIdRaw is int ? pointIdRaw : int.tryParse('$pointIdRaw');
      if (pointId == null) return;
      final comment = MapPointComment.fromJson(Map<String, dynamic>.from(commentJson));
      _cacheRecentComment(pointId, comment);
      final point = _findPointById(pointId);
      if (point != null) {
        onPointCommentAdded?.call(point, comment);
      }
      notifyListeners();
    });

    _socketService.onMapaTaticoMemberJoined((_) {
      if (_activeGroup != null) {
        unawaited(loadGroups());
      }
    });

    _socketService.onMapaTaticoLocationUpdated((data) {
      final locJson = data['location'];
      if (locJson is! Map) return;
      final loc = MapMemberLocation.fromJson(Map<String, dynamic>.from(locJson));
      if (_activeGroup == null || loc.userId == _currentUserId) return;
      _teamLocations.removeWhere((l) => l.userId == loc.userId);
      if (loc.sharingEnabled) _teamLocations.add(loc);
      notifyListeners();
    });
  }

  Future<void> _joinActiveGroupRoom() async {
    final groupId = _activeGroup?.id;
    if (groupId == null) return;
    if (_joinedGroupId != null && _joinedGroupId != groupId) {
      _socketService.leaveMapaTaticoGroup(_joinedGroupId!);
    }
    _socketService.joinMapaTaticoGroup(groupId);
    _joinedGroupId = groupId;
  }

  bool _shouldTrackPoint(MapPoint point) {
    final globalId = globalGroup?.id;
    if (globalId != null && point.groupId == globalId) return true;
    if (_activeGroup == null) return false;
    return point.groupId == _activeGroup!.id;
  }

  void _upsertInList(List<MapPoint> list, MapPoint point) {
    final index = list.indexWhere((p) => p.id == point.id);
    if (index >= 0) {
      list[index] = point;
    } else {
      list.insert(0, point);
    }
  }

  void _upsertPoint(MapPoint point) {
    if (point.isExpired) {
      _removePoint(point.id);
      return;
    }
    if (point.groupId == globalGroup?.id) {
      _upsertInList(_pointsNational, point);
    } else if (point.mapType == 'SHARED') {
      _upsertInList(_pointsShared, point);
    } else if (point.mapType == 'LOGISTICS') {
      _upsertInList(_pointsLogistics, point);
    } else {
      _upsertInList(_pointsOperational, point);
    }
    _checkProximity();
  }

  void _removePoint(int pointId) {
    _pointsOperational.removeWhere((p) => p.id == pointId);
    _pointsLogistics.removeWhere((p) => p.id == pointId);
    _pointsShared.removeWhere((p) => p.id == pointId);
    _pointsNational.removeWhere((p) => p.id == pointId);
    _alertedPointIds.remove(pointId);
    _recentCommentsByPointId.remove(pointId);
    _checkProximity();
  }

  MapPoint? _findPointById(int pointId) {
    for (final p in [..._pointsOperational, ..._pointsLogistics, ..._pointsShared, ..._pointsNational]) {
      if (p.id == pointId) return p;
    }
    return null;
  }

  void _cacheRecentComment(int pointId, MapPointComment comment) {
    final list = _recentCommentsByPointId.putIfAbsent(pointId, () => []);
    if (list.any((c) => c.id == comment.id)) return;
    list.insert(0, comment);
    if (list.length > 5) {
      list.removeRange(5, list.length);
    }
  }

  List<MapPointComment> recentCommentsForPoint(int pointId) {
    return List.unmodifiable(_recentCommentsByPointId[pointId] ?? const []);
  }

  List<MapPoint> _filteredPoints(List<MapPoint> source, MapaTaticoFilters filters) {
    if (!filters.hasActiveFilters) return List.unmodifiable(source);

    return source.where((point) {
      if (filters.types.isNotEmpty && !filters.types.contains(point.type)) {
        return false;
      }
      if (filters.onlyMine && _currentUserId != null && point.creatorId != _currentUserId) {
        return false;
      }
      if (filters.expiringWithinHours != null && point.expiresAt != null) {
        final limit = DateTime.now().add(Duration(hours: filters.expiringWithinHours!));
        if (point.expiresAt!.isAfter(limit)) return false;
      }
      if (filters.maxDistanceMeters != null && _currentPosition != null) {
        final distance = _locationService.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          point.lat,
          point.lng,
        );
        if (distance > filters.maxDistanceMeters!) return false;
      }
      return true;
    }).toList();
  }

  void setFiltersOperational(MapaTaticoFilters filters) {
    _filtersOperational = filters;
    notifyListeners();
  }

  void setFiltersLogistics(MapaTaticoFilters filters) {
    _filtersLogistics = filters;
    notifyListeners();
  }

  void clearFiltersForMapType(String mapType) {
    if (mapType == 'LOGISTICS') {
      _filtersLogistics = const MapaTaticoFilters();
    } else {
      _filtersOperational = const MapaTaticoFilters();
    }
    notifyListeners();
  }

  Future<void> setTileStyle(MapaTaticoTileStyle style) async {
    _tileStyle = style;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefTileStyle, style.name);
    } catch (_) {}
  }

  void setAppInForeground(bool value) {
    _isAppInForeground = value;
    if (value && !kIsWeb) {
      unawaited(requestAndRefreshCurrentLocation());
    } else if (!value) {
      _stopLocationStream();
      _stopProximityCheck();
    }
  }

  Future<void> setAlertRadius(double meters) async {
    _alertRadiusMeters = meters;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefAlertRadius, meters);
    } catch (_) {}
  }

  Future<void> loadGroups() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      try {
        _photoUploadEnabled = await _repository.isPhotoUploadEnabled();
      } catch (_) {
        _photoUploadEnabled = false;
      }
      _groups = await _repository.getGroups();
      _pendingInvites = await _repository.getPendingInvites();
      if (_activeGroup == null && _groups.isNotEmpty) {
        _activeGroup = privateGroups.isNotEmpty ? privateGroups.first : _groups.first;
      } else if (_activeGroup != null && !_activeGroup!.isGlobal) {
        try {
          final updated = _groups.firstWhere((g) => g.id == _activeGroup!.id);
          _activeGroup = updated;
        } catch (_) {}
      }

      if (_activeGroup != null && !_activeGroup!.isGlobal) {
        _isMuted = _activeGroup!.isMuted;
      }

      // Sempre carrega pontos (inclui Mapa Nacional quando só há grupo global).
      if (_groups.isNotEmpty) {
        await loadPoints();
      }

      await _joinActiveGroupRoom();
    } catch (e) {
      _setError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchGroup(int groupId) async {
    _errorMessage = null;
    try {
      final group = _groups.firstWhere((g) => g.id == groupId);
      if (group.isGlobal) return;
      await _repository.switchGroup(groupId);
      _activeGroup = group;
      _isMuted = _activeGroup!.isMuted;
      await loadPoints();
      await _joinActiveGroupRoom();
      notifyListeners();
    } catch (e) {
      _setError(e);
      notifyListeners();
    }
  }

  Future<void> leaveGroup(int groupId) async {
    _errorMessage = null;
    try {
      await _repository.leaveGroup(groupId);
      if (_joinedGroupId == groupId) {
        _socketService.leaveMapaTaticoGroup(groupId);
        _joinedGroupId = null;
      }
      await loadGroups();
      if (_activeGroup != null && _activeGroup!.id == groupId) {
        _activeGroup = _groups.isNotEmpty ? _groups.first : null;
      }
      if (_activeGroup == null) {
        _pointsOperational = [];
        _pointsLogistics = [];
      } else {
        _isMuted = _activeGroup!.isMuted;
        await loadPoints();
      }
      notifyListeners();
    } catch (e) {
      _setError(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> acceptInvite(int inviteId) async {
    _errorMessage = null;
    try {
      await _repository.acceptInvite(inviteId);
      _pendingInvites.removeWhere((i) => i.id == inviteId);
      await loadGroups();
      notifyListeners();
    } catch (e) {
      _setError(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> rejectInvite(int inviteId) async {
    _errorMessage = null;
    try {
      await _repository.rejectInvite(inviteId);
      _pendingInvites.removeWhere((i) => i.id == inviteId);
      notifyListeners();
    } catch (e) {
      _setError(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadPoints({bool full = true}) async {
    if (_activeGroup == null && globalGroup == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final group = _activeGroup;
      final global = globalGroup;

      // Todas as buscas em paralelo: evita 4 round-trips sequenciais.
      if (group != null && !group.isGlobal) {
        if (full || _lastPointsSyncAt == null) {
          final results = await Future.wait([
            _repository.getPoints(group.id, mapType: 'OPERATIONAL'),
            _repository.getPoints(group.id, mapType: 'LOGISTICS'),
            _repository.getPoints(group.id, mapType: 'SHARED'),
            if (global != null) _repository.getPoints(global.id, mapType: 'ALL'),
          ]);
          _pointsOperational = results[0];
          _pointsLogistics = results[1];
          _pointsShared = results[2];
          if (global != null) _pointsNational = results[3];
        } else {
          final since = _lastPointsSyncAt!;
          final results = await Future.wait([
            _repository.getPoints(group.id, mapType: 'OPERATIONAL', since: since),
            _repository.getPoints(group.id, mapType: 'LOGISTICS', since: since),
            _repository.getPoints(group.id, mapType: 'SHARED', since: since),
            if (global != null) _repository.getPoints(global.id, mapType: 'ALL'),
          ]);
          for (final p in [...results[0], ...results[1], ...results[2]]) {
            _upsertPoint(p);
          }
          if (global != null) _pointsNational = results[3];
        }
      } else if (global != null) {
        _pointsNational = await _repository.getPoints(global.id, mapType: 'ALL');
      }
      _lastPointsSyncAt = DateTime.now().toUtc();
      _alertedPointIds.clear();
      _checkProximity();
      unawaited(loadTeamLocations());
    } catch (e) {
      _setError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTeamLocations() async {
    if (_activeGroup == null) return;
    try {
      _teamLocations = await _repository.getMemberLocations(_activeGroup!.id);
      if (_currentUserId != null) {
        _teamLocations.removeWhere((l) => l.userId == _currentUserId);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setSharingLocation(bool enabled) async {
    _sharingLocationEnabled = enabled;
    _locationService.setBackgroundMode(enabled);
    if (_activeGroup == null) return;
    if (!enabled) {
      await _repository.stopSharingLocation(_activeGroup!.id);
      _stopTeamLocationSync();
      notifyListeners();
      return;
    }
    final ok = await requestAndRefreshCurrentLocation();
    if (!ok) {
      _sharingLocationEnabled = false;
      notifyListeners();
      return;
    }
    await _pushLocationToServer();
    _startTeamLocationSync();
    notifyListeners();
  }

  void _startTeamLocationSync() {
    _teamLocationSyncTimer?.cancel();
    _teamLocationSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_sharingLocationEnabled) return;
      unawaited(_pushLocationToServer());
    });
  }

  void _stopTeamLocationSync() {
    _teamLocationSyncTimer?.cancel();
    _teamLocationSyncTimer = null;
  }

  Future<void> _pushLocationToServer() async {
    if (_activeGroup == null || _currentPosition == null || !_sharingLocationEnabled) return;
    try {
      await _repository.updateMemberLocation(
        _activeGroup!.id,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        sharingEnabled: true,
      );
    } catch (_) {}
  }

  Future<List<AddressSearchResult>> geocodeSearch(String query) async {
    try {
      return await _repository.geocodeSearch(query);
    } catch (e) {
      _setError(e);
      return [];
    }
  }

  Future<String?> geocodeReverse(double lat, double lng) async {
    try {
      return await _repository.geocodeReverse(lat, lng);
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> getAudit(int pointId) async {
    try {
      return await _repository.getAudit(pointId);
    } catch (e) {
      _setError(e);
      return [];
    }
  }

  Future<Map<String, dynamic>?> getIntelligence(String mapType, {int days = 7}) async {
    if (_activeGroup == null) return null;
    try {
      return await _repository.getIntelligence(_activeGroup!.id, mapType, days: days);
    } catch (e) {
      _setError(e);
      return null;
    }
  }

  Future<MapGroup?> createGroup(String name) async {
    _errorMessage = null;
    try {
      final group = await _repository.createGroup(name);
      _groups.add(group);
      _activeGroup = group;
      await loadPoints();
      await _joinActiveGroupRoom();
      notifyListeners();
      return group;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> inviteToGroup(String email) async {
    if (_activeGroup == null) return;
    _errorMessage = null;
    try {
      await _repository.inviteToGroup(_activeGroup!.id, email);
      notifyListeners();
    } catch (e) {
      _setError(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<List<MapGroupMember>> getGroupMembers() async {
    if (_activeGroup == null) return [];
    try {
      return await _repository.getGroupMembers(_activeGroup!.id);
    } catch (e) {
      _setError(e);
      notifyListeners();
      return [];
    }
  }

  Future<void> muteMember(int userId, bool isMuted) async {
    if (_activeGroup == null) return;
    _errorMessage = null;
    try {
      await _repository.muteMember(_activeGroup!.id, userId, isMuted);
      await loadGroups();
    } catch (e) {
      _setError(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeMember(int userId) async {
    if (_activeGroup == null) return;
    _errorMessage = null;
    try {
      await _repository.removeMember(_activeGroup!.id, userId);
      await loadGroups();
    } catch (e) {
      _setError(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateMemberNomeDeGuerra(int userId, String nomeDeGuerra) async {
    if (_activeGroup == null) return;
    _errorMessage = null;
    try {
      await _repository.updateMemberNomeDeGuerra(_activeGroup!.id, userId, nomeDeGuerra);
      await loadGroups();
    } catch (e) {
      _setError(e);
      notifyListeners();
      rethrow;
    }
  }

  void startLocationTracking() {
    _startLocationStream();
    _startProximityCheck();
  }

  void stopLocationTracking() {
    _stopLocationStream();
    _stopProximityCheck();
  }

  Future<bool> requestAndRefreshCurrentLocation() async {
    final hasPermission = await _locationService.ensurePermission();
    if (!hasPermission) {
      _errorMessage = _locationService.locationUnavailableMessage;
      notifyListeners();
      return false;
    }
    await _refreshCurrentPosition();
    _startLocationStream();
    _startProximityCheck();
    return _currentPosition != null;
  }

  void _startLocationStream() {
    if (_isLocationStreamActive) return;
    _isLocationStreamActive = true;
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.getLocationStream().listen(
      (position) {
        _currentPosition = position;
        _lastPositionAt = DateTime.now();
        _checkProximity();
        if (_sharingLocationEnabled) {
          unawaited(_pushLocationToServer());
        }
        notifyListeners();
      },
      onError: (_) {
        _isLocationStreamActive = false;
        _refreshCurrentPosition();
      },
      onDone: () {
        _isLocationStreamActive = false;
      },
    );
  }

  void _stopLocationStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isLocationStreamActive = false;
  }

  Future<void> _refreshCurrentPosition() async {
    if (_isRefreshingPosition) return;
    _isRefreshingPosition = true;
    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) return;
      _currentPosition = position;
      _lastPositionAt = DateTime.now();
      _checkProximity();
      notifyListeners();
    } catch (_) {
    } finally {
      _isRefreshingPosition = false;
    }
  }

  void _startProximityCheck() {
    if (_proximityCheckTimer != null) return;
    _proximityCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isAppInForeground) return;
      unawaited(_refreshCurrentPosition());
    });
  }

  void _stopProximityCheck() {
    _proximityCheckTimer?.cancel();
    _proximityCheckTimer = null;
  }

  void _checkProximity() {
    if (_currentPosition == null) return;
    // Alerta de proximidade apenas para pontos operacionais
    final operationalPoints = _pointsOperational;
    if (operationalPoints.isEmpty) {
      if (_hasNearbyPointInAlertRadius) {
        _hasNearbyPointInAlertRadius = false;
        notifyListeners();
      }
      return;
    }

    var hasNearby = false;
    MapPoint? closestNewAlert;

    for (final point in operationalPoints) {
      if (!triggersProximityAlert(point.type)) continue;

      final distance = _locationService.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        point.lat,
        point.lng,
      );

      if (distance > _alertRadiusMeters * 1.5) {
        _alertedPointIds.remove(point.id);
      }

      if (distance <= _alertRadiusMeters) {
        hasNearby = true;
        if (!_alertedPointIds.contains(point.id)) {
          closestNewAlert ??= point;
        }
      }
    }

    final alertPoint = closestNewAlert;
    if (alertPoint != null && onProximityAlert != null) {
      _alertedPointIds.add(alertPoint.id);
      onProximityAlert!.call(alertPoint);
    }

    if (_hasNearbyPointInAlertRadius != hasNearby) {
      _hasNearbyPointInAlertRadius = hasNearby;
      notifyListeners();
    }
  }

  double? distanceToPoint(MapPoint point) {
    if (_currentPosition == null) return null;
    return _locationService.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      point.lat,
      point.lng,
    );
  }

  List<MapPoint> logisticsNear(double lat, double lng, {double radiusMeters = 500}) {
    return _pointsLogistics.where((point) {
      final distance = _locationService.distanceBetween(lat, lng, point.lat, point.lng);
      return distance <= radiusMeters;
    }).toList();
  }

  Future<MapPoint?> createPoint({
    required String title,
    String? address,
    String? description,
    required double lat,
    required double lng,
    required String type,
    required String mapType,
    DateTime? expiresAt,
    dynamic photo,
  }) async {
    if (mapType == 'NATIONAL') {
      if (globalGroup == null) {
        _errorMessage = 'Mapa Nacional indisponível.';
        return null;
      }
    } else if (_activeGroup == null || _activeGroup!.isGlobal) {
      return null;
    }
    _errorMessage = null;
    try {
      final targetGroupId = mapType == 'NATIONAL' ? globalGroup!.id : _activeGroup!.id;
      final resolvedMapType = resolveMapTypeForPointType(type, mapType == 'NATIONAL' ? 'SHARED' : mapType);

      final point = await _repository.createPoint(
        groupId: targetGroupId,
        title: title,
        address: address,
        description: description,
        lat: lat,
        lng: lng,
        type: type,
        mapType: resolvedMapType,
        expiresAt: expiresAt,
        photo: photo,
      );
      _upsertPoint(point);
      notifyListeners();
      return point;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return null;
    }
  }

  Future<MapPoint?> getPoint(int pointId) async {
    try {
      return await _repository.getPoint(pointId);
    } catch (e) {
      _setError(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> updatePoint(int pointId, Map<String, dynamic> data, {dynamic photo}) async {
    _errorMessage = null;
    try {
      final updated = await _repository.updatePoint(pointId, data, photo: photo);
      _upsertPoint(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePoint(int pointId) async {
    _errorMessage = null;
    try {
      await _repository.deletePoint(pointId);
      _removePoint(pointId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return false;
    }
  }

  Future<List<MapPointComment>> getComments(int pointId, {int limit = 50, int offset = 0}) async {
    try {
      final comments = await _repository.getComments(pointId, limit: limit, offset: offset);
      if (offset == 0) {
        _recentCommentsByPointId[pointId] = comments.take(5).toList();
      }
      return comments;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return [];
    }
  }

  Future<MapPointComment?> addComment(int pointId, String text) async {
    _errorMessage = null;
    try {
      final comment = await _repository.createComment(pointId, text);
      _cacheRecentComment(pointId, comment);
      return comment;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> reportPoint(int pointId, {String? reason}) async {
    _errorMessage = null;
    try {
      await _repository.reportPoint(pointId, reason: reason);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerVisit(int pointId) async {
    _errorMessage = null;
    try {
      await _repository.createVisit(pointId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return false;
    }
  }

  Future<List<MapPointVisit>> getVisits(int pointId, {int lastDays = 7}) async {
    try {
      return await _repository.getVisits(pointId, lastDays: lastDays);
    } catch (e) {
      _setError(e);
      notifyListeners();
      return [];
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_joinedGroupId != null) {
      _socketService.leaveMapaTaticoGroup(_joinedGroupId!);
    }
    _positionSubscription?.cancel();
    _proximityCheckTimer?.cancel();
    _teamLocationSyncTimer?.cancel();
    _locationService.dispose();
    super.dispose();
  }
}

extension on MapPoint {
  bool get isExpired {
    final expires = expiresAt;
    if (expires == null) return false;
    return expires.isBefore(DateTime.now());
  }
}
