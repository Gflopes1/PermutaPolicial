import '../api_client.dart';

class MapaTaticoAdminRepository {
  final ApiClient _apiClient;
  MapaTaticoAdminRepository(this._apiClient);

  static const String _base = '/api/admin/mapa-tatico';

  Future<Map<String, dynamic>> listGroups({int page = 1, int limit = 20, String? search}) async {
    var query = '?page=$page&limit=$limit';
    if (search != null && search.isNotEmpty) {
      query += '&search=${Uri.encodeQueryComponent(search)}';
    }
    final response = await _apiClient.get('$_base/groups$query');
    if (response is Map && response.containsKey('data')) {
      return response['data'] as Map<String, dynamic>;
    }
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getGroupDetail(int groupId, {int limit = 50, int offset = 0}) async {
    final response = await _apiClient.get('$_base/groups/$groupId?limit=$limit&offset=$offset');
    if (response is Map && response.containsKey('data')) {
      return response['data'] as Map<String, dynamic>;
    }
    return response as Map<String, dynamic>;
  }

  Future<void> removePoint(int groupId, int pointId) async {
    await _apiClient.delete('$_base/groups/$groupId/points/$pointId');
  }

  Future<void> removeMember(int groupId, int userId, String motivo) async {
    await _apiClient.deleteWithBody('$_base/groups/$groupId/members/$userId', {'motivo': motivo});
  }
}
