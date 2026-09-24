// /lib/core/api/repositories/policiais_repository.dart

import '../../models/user_profile.dart';
import '../api_client.dart';
import '../../../features/profile/utils/profile_photo_upload.dart';

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

  Future<String> uploadProfilePhoto(List<int> photoBytes, {String? photoFilename}) async {
    final file = buildProfilePhotoMultipart(photoBytes, filename: photoFilename);
    final responseData = await _apiClient.postMultipart('/api/policiais/me/photo', {}, [file]);
    final data = responseData is Map ? responseData['foto_perfil'] : null;
    return data?.toString() ?? '';
  }

  Future<void> deleteProfilePhoto() async {
    await _apiClient.delete('/api/policiais/me/photo');
  }
}