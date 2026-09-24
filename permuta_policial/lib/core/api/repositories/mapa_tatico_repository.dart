// /lib/core/api/repositories/mapa_tatico_repository.dart

import 'package:http/http.dart' as http;

import '../api_client.dart';
import '../../../features/mapa_tatico/models/map_group.dart';
import '../../../features/mapa_tatico/models/map_point.dart';
import '../../../features/mapa_tatico/models/map_occurrence_log_entry.dart';
import '../../../features/mapa_tatico/models/map_suspect_profile.dart';
import '../../../features/mapa_tatico/models/map_point_comment.dart';
import '../../../features/mapa_tatico/models/map_point_visit.dart';
import '../../../features/mapa_tatico/models/group_invite.dart';
import '../../../features/mapa_tatico/models/map_group_member.dart';
import '../../../features/mapa_tatico/models/map_member_location.dart';
import '../../../features/mapa_tatico/models/address_search_result.dart';

class MapaTaticoRepository {
  final ApiClient _apiClient;

  MapaTaticoRepository(this._apiClient);

  static const String _base = '/api/mapa-tatico';

  T _data<T>(dynamic response, T Function(dynamic) parse) {
    if (response is Map && response.containsKey('data')) {
      return parse(response['data']);
    }
    return parse(response);
  }

  List<T> _list<T>(dynamic response, T Function(dynamic) parse) {
    dynamic data = response;
    if (response is Map && response.containsKey('data')) {
      data = response['data'];
    }
    if (data is List) {
      return data.map((e) => parse(e)).toList();
    }
    return [];
  }

  // ========== GRUPOS ==========
  Future<bool> isPhotoUploadEnabled() async {
    final response = await _apiClient.get('$_base/status');
    final data = _data(response, (d) => d as Map<String, dynamic>);
    return data['photo_upload_enabled'] == true;
  }

  Future<MapGroup> createGroup(String name) async {
    final response = await _apiClient.post('$_base/groups', {'name': name});
    return MapGroup.fromJson(_data(response, (d) => d as Map<String, dynamic>));
  }

  Future<List<MapGroup>> getGroups() async {
    final response = await _apiClient.get('$_base/groups');
    return _list(response, (e) => MapGroup.fromJson(e as Map<String, dynamic>));
  }

  Future<void> switchGroup(int groupId) async {
    await _apiClient.post('$_base/groups/$groupId/switch', {});
  }

  Future<void> leaveGroup(int groupId) async {
    await _apiClient.post('$_base/groups/$groupId/leave', {});
  }

  Future<List<GroupInvite>> getPendingInvites() async {
    final response = await _apiClient.get('$_base/groups/invites/pending');
    return _list(response, (e) => GroupInvite.fromJson(e as Map<String, dynamic>));
  }

  Future<MapGroup> acceptInvite(int inviteId) async {
    final response = await _apiClient.post('$_base/groups/invites/$inviteId/accept', {});
    return MapGroup.fromJson(_data(response, (d) => d as Map<String, dynamic>));
  }

  Future<void> rejectInvite(int inviteId) async {
    await _apiClient.post('$_base/groups/invites/$inviteId/reject', {});
  }

  Future<void> inviteToGroup(int groupId, String email) async {
    await _apiClient.post('$_base/groups/$groupId/invite', {'email': email});
  }

  Future<List<MapGroupMember>> getGroupMembers(int groupId) async {
    final response = await _apiClient.get('$_base/groups/$groupId/members');
    return _list(response, (e) => MapGroupMember.fromJson(e as Map<String, dynamic>));
  }

  Future<void> updateNomeDeGuerra(int groupId, String nomeDeGuerra) async {
    await _apiClient.patch('$_base/groups/$groupId/nome-de-guerra', {'nome_de_guerra': nomeDeGuerra});
  }

  Future<void> updateMemberNomeDeGuerra(int groupId, int userId, String nomeDeGuerra) async {
    await _apiClient.patch(
      '$_base/groups/$groupId/members/$userId/nome-de-guerra',
      {'nome_de_guerra': nomeDeGuerra},
    );
  }

  Future<void> muteMember(int groupId, int userId, bool isMuted) async {
    await _apiClient.patch('$_base/groups/$groupId/members/$userId/mute', {'is_muted': isMuted});
  }

  Future<void> removeMember(int groupId, int userId) async {
    await _apiClient.delete('$_base/groups/$groupId/members/$userId');
  }

  Future<void> promoteMember(int groupId, int userId) async {
    await _apiClient.patch('$_base/groups/$groupId/members/$userId/promote', {});
  }

  // ========== PONTOS ==========
  Future<MapPoint> createPoint({
    required int groupId,
    required String title,
    String? address,
    String? description,
    required double lat,
    required double lng,
    required String type,
    required String mapType,
    MapPointVisibility visibility = MapPointVisibility.group,
    DateTime? expiresAt,
    http.MultipartFile? photo,
    List<http.MultipartFile>? photos,
  }) async {
    final data = {
      'group_id': groupId.toString(),
      'title': title,
      'address': address ?? '',
      if (description != null && description.isNotEmpty) 'description': description,
      'lat': lat.toString(),
      'lng': lng.toString(),
      'type': type,
      'map_type': mapType,
      'visibility': visibility.value,
      if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
    };
    final files = <http.MultipartFile>[
      ...?photos,
      if (photo != null) photo,
    ];
    if (files.length > 10) {
      throw Exception('Máximo de 10 fotos por ponto.');
    }
    final dynamic response;
    if (files.isEmpty) {
      response = await _apiClient.post('$_base/points', {
        'group_id': groupId,
        'title': title,
        if (address != null && address.isNotEmpty) 'address': address,
        if (description != null && description.isNotEmpty) 'description': description,
        'lat': lat,
        'lng': lng,
        'type': type,
        'map_type': mapType,
        'visibility': visibility.value,
        if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
      });
    } else {
      response = await _apiClient.postMultipart(
        '$_base/points',
        data,
        files,
      );
    }
    return MapPoint.fromJson(_data(response, (d) => d as Map<String, dynamic>));
  }

  Future<List<MapPoint>> getPoints(
    int groupId, {
    String? mapType,
    DateTime? since,
  }) async {
    var query = '?group_id=$groupId';
    if (mapType != null) query += '&map_type=$mapType';
    if (since != null) query += '&since=${since.toUtc().toIso8601String()}';
    final response = await _apiClient.get('$_base/points$query');
    return _list(response, (e) => MapPoint.fromJson(e as Map<String, dynamic>));
  }

  Future<MapPoint> getPoint(int pointId) async {
    final response = await _apiClient.get('$_base/points/$pointId');
    return MapPoint.fromJson(_data(response, (d) => d as Map<String, dynamic>));
  }

  Future<MapPoint> updatePoint(int pointId, Map<String, dynamic> data, {http.MultipartFile? photo}) async {
    if (photo != null) {
      final strData = Map<String, String>.from(
        data.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      );
      final response = await _apiClient.putMultipart('$_base/points/$pointId', strData, [photo]);
      return MapPoint.fromJson(_data(response, (d) => d as Map<String, dynamic>));
    } else {
      final response = await _apiClient.patch('$_base/points/$pointId', data);
      return MapPoint.fromJson(_data(response, (d) => d as Map<String, dynamic>));
    }
  }

  Future<void> deletePoint(int pointId) async {
    await _apiClient.delete('$_base/points/$pointId');
  }

  // ========== COMENTÁRIOS ==========
  Future<MapPointComment> createComment(int pointId, String text) async {
    final response = await _apiClient.post('$_base/points/$pointId/comments', {'text': text});
    return MapPointComment.fromJson(_data(response, (d) => d as Map<String, dynamic>));
  }

  Future<List<MapPointComment>> getComments(int pointId, {int limit = 50, int offset = 0}) async {
    final response = await _apiClient.get(
      '$_base/points/$pointId/comments?limit=$limit&offset=$offset',
    );
    return _list(response, (e) => MapPointComment.fromJson(e as Map<String, dynamic>));
  }

  // ========== DENÚNCIAS ==========
  Future<void> reportPoint(int pointId, {String? reason}) async {
    await _apiClient.post('$_base/points/$pointId/report', {'reason': reason ?? ''});
  }

  // ========== VISITAS ==========
  Future<void> createVisit(int pointId) async {
    await _apiClient.post('$_base/points/$pointId/visit', {});
  }

  Future<List<MapPointVisit>> getVisits(int pointId, {int lastDays = 7}) async {
    final response = await _apiClient.get('$_base/points/$pointId/visits?lastDays=$lastDays');
    return _list(response, (e) => MapPointVisit.fromJson(e as Map<String, dynamic>));
  }

  // ========== AUDITORIA ==========
  Future<List<dynamic>> getAudit(int pointId) async {
    final response = await _apiClient.get('$_base/points/$pointId/audit');
    dynamic data = response;
    if (response is Map && response.containsKey('data')) {
      data = response['data'];
    }
    if (data is List) return data;
    return [];
  }

  Future<List<AddressSearchResult>> geocodeSearch(String query) async {
    final response = await _apiClient.get('$_base/geocode/search?q=${Uri.encodeQueryComponent(query)}');
    return _list(response, (e) {
      final m = e as Map<String, dynamic>;
      return AddressSearchResult(
        displayName: m['display_name'] as String? ?? '',
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
      );
    });
  }

  Future<String?> geocodeReverse(double lat, double lng) async {
    final response = await _apiClient.get('$_base/geocode/reverse?lat=$lat&lng=$lng');
    final data = _data(response, (d) => d as Map<String, dynamic>);
    return data['display_name'] as String?;
  }

  Future<void> updateMemberLocation(int groupId, double lat, double lng, {bool sharingEnabled = true}) async {
    await _apiClient.put('$_base/groups/$groupId/location', {
      'lat': lat,
      'lng': lng,
      'sharing_enabled': sharingEnabled,
    });
  }

  Future<void> stopSharingLocation(int groupId) async {
    await _apiClient.delete('$_base/groups/$groupId/location');
  }

  Future<List<MapMemberLocation>> getMemberLocations(int groupId, {int maxAgeMinutes = 30}) async {
    final response = await _apiClient.get('$_base/groups/$groupId/locations?max_age_minutes=$maxAgeMinutes');
    return _list(response, (e) => MapMemberLocation.fromJson(e as Map<String, dynamic>));
  }

  Future<Map<String, dynamic>> getIntelligence(int groupId, String mapType, {int days = 7}) async {
    final response = await _apiClient.get('$_base/groups/$groupId/intelligence?map_type=$mapType&days=$days');
    return _data(response, (d) => d as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> listReports() async {
    final response = await _apiClient.get('$_base/reports');
    return _list(response, (e) => e as Map<String, dynamic>);
  }

  Future<void> reviewReport(int reportId, String status, {String? adminNotes}) async {
    await _apiClient.patch('$_base/reports/$reportId', {
      'status': status,
      if (adminNotes != null) 'admin_notes': adminNotes,
    });
  }

  Future<MapPoint> deletePointPhoto(int pointId, int photoId) async {
    final response = await _apiClient.delete('$_base/points/$pointId/photos/$photoId');
    return MapPoint.fromJson(_data(response, (d) => d as Map<String, dynamic>));
  }

  Future<List<MapOccurrenceLogEntry>> getOccurrenceLog(int pointId) async {
    final response = await _apiClient.get('$_base/points/$pointId/occurrence-log');
    return _list(response, (e) => MapOccurrenceLogEntry.fromJson(e as Map<String, dynamic>));
  }

  Future<MapOccurrenceLogEntry> createOccurrenceLogEntry(
    int pointId, {
    required String narrative,
    String? entryType,
    String? status,
    DateTime? occurredAt,
  }) async {
    final response = await _apiClient.post('$_base/points/$pointId/occurrence-log', {
      'narrative': narrative,
      if (entryType != null) 'entry_type': entryType,
      if (status != null) 'status': status,
      if (occurredAt != null) 'occurred_at': occurredAt.toIso8601String(),
    });
    return MapOccurrenceLogEntry.fromJson(_data(response, (d) => d as Map<String, dynamic>));
  }

  Future<MapSuspectProfile?> getSuspectProfile(int pointId) async {
    final response = await _apiClient.get('$_base/points/$pointId/suspect-profile');
    final data = _data(response, (d) => d);
    if (data == null) return null;
    return MapSuspectProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<MapSuspectProfile> upsertSuspectProfile(int pointId, Map<String, dynamic> data) async {
    final response = await _apiClient.put('$_base/points/$pointId/suspect-profile', data);
    return MapSuspectProfile.fromJson(_data(response, (d) => d as Map<String, dynamic>));
  }

  Future<bool> getSuspectDisclaimerAcknowledged() async {
    final response = await _apiClient.get('$_base/suspect-profile/disclaimer');
    final data = _data(response, (d) => d as Map<String, dynamic>);
    return data['acknowledged'] == true;
  }

  Future<void> acknowledgeSuspectDisclaimer() async {
    await _apiClient.post('$_base/suspect-profile/disclaimer', {});
  }
}
