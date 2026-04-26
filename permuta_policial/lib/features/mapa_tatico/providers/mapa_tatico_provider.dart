// /lib/features/mapa_tatico/providers/mapa_tatico_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/repositories/mapa_tatico_repository.dart';
import '../models/map_group.dart';
import '../models/map_point.dart';
import '../models/map_point_comment.dart';
import '../models/map_point_visit.dart';
import '../models/group_invite.dart';
import '../models/map_group_member.dart';
import '../models/patrol_location.dart';
import '../services/location_tracking_service.dart';

class MapaTaticoProvider with ChangeNotifier {
  final MapaTaticoRepository _repository;
  final LocationTrackingService _locationService = createLocationTrackingService();

  MapaTaticoProvider(this._repository);

  List<MapGroup> _groups = [];
  MapGroup? _activeGroup;
  List<MapPoint> _pointsOperational = [];
  List<MapPoint> _pointsLogistics = [];
  List<GroupInvite> _pendingInvites = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isMuted = false;
  double _alertRadiusMeters = 200;
  PatrolLocation? _currentPosition;
  DateTime? _lastPositionAt;
  bool _hasNearbyPointInAlertRadius = false;
  StreamSubscription<PatrolLocation>? _positionSubscription;
  Timer? _proximityCheckTimer;
  final Set<int> _alertedPointIds = {};
  bool _isAppInForeground = true;

  List<MapGroup> get groups => _groups;
  MapGroup? get activeGroup => _activeGroup;
  List<MapPoint> get pointsOperational => _pointsOperational;
  List<MapPoint> get pointsLogistics => _pointsLogistics;
  List<GroupInvite> get pendingInvites => _pendingInvites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isMuted => _isMuted;
  double get alertRadiusMeters => _alertRadiusMeters;
  PatrolLocation? get currentPosition => _currentPosition;
  DateTime? get lastPositionAt => _lastPositionAt;
  bool get hasNearbyPointInAlertRadius => _hasNearbyPointInAlertRadius;

  VoidCallback? onProximityAlert;

  void setAppInForeground(bool value) {
    _isAppInForeground = value;
    if (value) {
      _startLocationStream();
      _startProximityCheck();
    } else {
      _stopLocationStream();
      _stopProximityCheck();
    }
  }

  void setAlertRadius(double meters) {
    _alertRadiusMeters = meters;
    notifyListeners();
  }

  Future<void> loadGroups() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _groups = await _repository.getGroups();
      _pendingInvites = await _repository.getPendingInvites();
      if (_activeGroup == null && _groups.isNotEmpty) {
        _activeGroup = _groups.first;
        _isMuted = _activeGroup!.isMuted;
        await loadPoints();
      } else if (_activeGroup != null) {
        try {
          final updated = _groups.firstWhere((g) => g.id == _activeGroup!.id);
          _activeGroup = updated;
          _isMuted = updated.isMuted;
          await loadPoints();
        } catch (_) {}
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchGroup(int groupId) async {
    _errorMessage = null;
    try {
      await _repository.switchGroup(groupId);
      _activeGroup = _groups.firstWhere((g) => g.id == groupId);
      _isMuted = _activeGroup!.isMuted;
      await loadPoints();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> leaveGroup(int groupId) async {
    _errorMessage = null;
    try {
      await _repository.leaveGroup(groupId);
      await loadGroups();
      if (_activeGroup != null && _activeGroup!.id == groupId) {
        _activeGroup = _groups.isNotEmpty ? _groups.first : null;
      }
      if (_activeGroup == null) {
        _pointsOperational = [];
        _pointsLogistics = [];
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> acceptInvite(int inviteId) async {
    _errorMessage = null;
    try {
      final group = await _repository.acceptInvite(inviteId);
      _groups.add(group);
      _pendingInvites.removeWhere((i) => i.id == inviteId);
      _activeGroup ??= group;
      await loadPoints();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
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
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadPoints() async {
    if (_activeGroup == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _pointsOperational = await _repository.getPoints(_activeGroup!.id, mapType: 'OPERATIONAL');
      _pointsLogistics = await _repository.getPoints(_activeGroup!.id, mapType: 'LOGISTICS');
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MapGroup?> createGroup(String name) async {
    _errorMessage = null;
    try {
      final group = await _repository.createGroup(name);
      _groups.add(group);
      _activeGroup = group;
      await loadPoints();
      notifyListeners();
      return group;
    } catch (e) {
      _errorMessage = e.toString();
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
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<MapGroupMember>> getGroupMembers() async {
    if (_activeGroup == null) return [];
    try {
      return await _repository.getGroupMembers(_activeGroup!.id);
    } catch (e) {
      _errorMessage = e.toString();
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
      _errorMessage = e.toString();
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
      _errorMessage = e.toString();
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
      _errorMessage = e.toString();
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
    if (!hasPermission) return false;
    await _refreshCurrentPosition();
    _startLocationStream();
    _startProximityCheck();
    return _currentPosition != null;
  }

  void _startLocationStream() {
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.getLocationStream().listen(
      (position) {
        _currentPosition = position;
        _lastPositionAt = DateTime.now();
        notifyListeners();
      },
      onError: (_) {
        _refreshCurrentPosition();
      },
    );
  }

  void _stopLocationStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _refreshCurrentPosition() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) return;
      _currentPosition = position;
      _lastPositionAt = DateTime.now();
      notifyListeners();
    } catch (_) {
      // Silencia falhas de localização em background para não quebrar a tela.
    }
  }

  void _startProximityCheck() {
    _proximityCheckTimer?.cancel();
    _proximityCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isAppInForeground) return;
      _checkProximity();
    });
  }

  void _stopProximityCheck() {
    _proximityCheckTimer?.cancel();
    _proximityCheckTimer = null;
  }

  void _checkProximity() {
    if (_currentPosition == null) return;
    final allPoints = [..._pointsOperational, ..._pointsLogistics];
    var hasNearby = false;
    for (final point in allPoints) {
      final distance = _locationService.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        point.lat,
        point.lng,
      );
      if (distance <= _alertRadiusMeters && !_alertedPointIds.contains(point.id)) {
        _alertedPointIds.add(point.id);
        onProximityAlert?.call();
      }
      if (distance <= _alertRadiusMeters) {
        hasNearby = true;
      }
    }
    if (_hasNearbyPointInAlertRadius != hasNearby) {
      _hasNearbyPointInAlertRadius = hasNearby;
      notifyListeners();
    }
  }

  List<MapPoint> get allPoints => [..._pointsOperational, ..._pointsLogistics];

  Future<MapPoint?> createPoint({
    required String title,
    String? address,
    required double lat,
    required double lng,
    required String type,
    required String mapType,
    DateTime? expiresAt,
    dynamic photo,
  }) async {
    if (_activeGroup == null) return null;
    _errorMessage = null;
    try {
      final point = await _repository.createPoint(
        groupId: _activeGroup!.id,
        title: title,
        address: address,
        lat: lat,
        lng: lng,
        type: type,
        mapType: mapType,
        expiresAt: expiresAt,
        photo: photo,
      );
      await loadPoints();
      notifyListeners();
      return point;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<MapPoint?> getPoint(int pointId) async {
    try {
      return await _repository.getPoint(pointId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updatePoint(int pointId, Map<String, dynamic> data, {dynamic photo}) async {
    _errorMessage = null;
    try {
      await _repository.updatePoint(pointId, data, photo: photo);
      await loadPoints();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePoint(int pointId) async {
    _errorMessage = null;
    try {
      await _repository.deletePoint(pointId);
      await loadPoints();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<MapPointComment>> getComments(int pointId) async {
    try {
      return await _repository.getComments(pointId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<MapPointComment?> addComment(int pointId, String text) async {
    _errorMessage = null;
    try {
      return await _repository.createComment(pointId, text);
    } catch (e) {
      _errorMessage = e.toString();
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
      _errorMessage = e.toString();
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
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<MapPointVisit>> getVisits(int pointId, {int lastDays = 7}) async {
    try {
      return await _repository.getVisits(pointId, lastDays: lastDays);
    } catch (e) {
      _errorMessage = e.toString();
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
    _positionSubscription?.cancel();
    _proximityCheckTimer?.cancel();
    _locationService.dispose();
    super.dispose();
  }
}
