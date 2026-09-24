import '../api_client.dart';

class ReferralRepository {
  final ApiClient _apiClient;

  ReferralRepository(this._apiClient);

  Future<Map<String, dynamic>> validateCode(String code) async {
    final data = await _apiClient.get(
      '/api/referral/validate/${Uri.encodeComponent(code)}',
      requireAuth: false,
    );
    return data as Map<String, dynamic>;
  }

  Future<void> registerClick(String code) async {
    await _apiClient.post(
      '/api/referral/click',
      {'code': code},
      requireAuth: false,
    );
  }

  Future<Map<String, dynamic>> getMyReferral() async {
    final data = await _apiClient.get('/api/referral/me');
    return data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getRanking({
    String scope = 'forca',
    int? forcaId,
    int? estadoId,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, String>{
      'scope': scope,
      'page': '$page',
      'limit': '$limit',
    };
    if (forcaId != null) query['forca_id'] = '$forcaId';
    if (estadoId != null) query['estado_id'] = '$estadoId';
    final qs = query.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final data = await _apiClient.get('/api/referral/ranking?$qs');
    if (data is List) return data;
    return [];
  }

  Future<Map<String, dynamic>?> getActiveCampaign() async {
    final data = await _apiClient.get(
      '/api/referral/campaign/active',
      requireAuth: false,
    );
    if (data == null) return null;
    return data as Map<String, dynamic>;
  }

  Future<void> dismissCampaign(String campaignId) async {
    await _apiClient.post('/api/referral/dismiss-campaign', {'campaign_id': campaignId});
  }

  Future<void> trackShare({Map<String, dynamic>? metadata}) async {
    await _apiClient.post('/api/referral/track-share', metadata ?? {});
  }

  Future<Map<String, dynamic>> attachReferral(String referralCode) async {
    final data = await _apiClient.post('/api/referral/attach', {
      'referral_code': referralCode,
    });
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    final data = await _apiClient.get('/api/admin/referral/stats');
    return data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getAdminRanking({
    String scope = 'geral',
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _apiClient.get(
      '/api/admin/referral/ranking?scope=$scope&limit=$limit&offset=$offset',
    );
    if (data is List) return data;
    return [];
  }

  Future<Map<String, dynamic>> getAdminUserDetail(int userId) async {
    final data = await _apiClient.get('/api/admin/referral/users/$userId');
    return data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getForceGoals() async {
    final data = await _apiClient.get('/api/admin/referral/force-goals');
    if (data is List) return data;
    return [];
  }

  Future<Map<String, dynamic>?> getAdminCampaign() async {
    final data = await _apiClient.get('/api/admin/referral/campaign');
    if (data == null) return null;
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveAdminCampaign(Map<String, dynamic> payload) async {
    final data = await _apiClient.put('/api/admin/referral/campaign', payload);
    return data as Map<String, dynamic>;
  }
}
