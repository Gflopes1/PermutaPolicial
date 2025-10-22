// /lib/core/api/repositories/policiais_repository.dart

import '../../models/user_profile.dart';
import '../api_client.dart';

class PoliciaisRepository {
  final ApiClient _apiClient;

  PoliciaisRepository(this._apiClient);

  // CORREÇÃO APLICADA AQUI
  Future<UserProfile> getMyProfile({String? token}) async {
    // Passa o token para a chamada do ApiClient
    final responseData = await _apiClient.get('/api/policiais/me', token: token);
    return UserProfile.fromJson(responseData);
  }

  Future<void> updateMyProfile(Map<String, dynamic> profileData) async {
    await _apiClient.put('/api/policiais/me', profileData);
  }
}