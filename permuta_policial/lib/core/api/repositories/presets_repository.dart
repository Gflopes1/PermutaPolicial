// /lib/core/api/repositories/presets_repository.dart

import '../api_client.dart';
import '../../models/preset.dart';

class PresetsRepository {
  final ApiClient _apiClient;

  PresetsRepository(this._apiClient);

  Future<List<Preset>> getPresets() async {
    final responseData = await _apiClient.get('/api/presets');
    return (responseData as List)
        .map((json) => Preset.fromJson(json))
        .toList();
  }

  Future<Preset> getPresetById(int id) async {
    final responseData = await _apiClient.get('/api/presets/$id');
    return Preset.fromJson(responseData);
  }

  Future<Preset> createPreset(Preset preset) async {
    final responseData = await _apiClient.post('/api/presets', preset.toJson());
    return Preset.fromJson(responseData);
  }

  Future<Preset> updatePreset(int id, Preset preset) async {
    final responseData = await _apiClient.put('/api/presets/$id', preset.toJson());
    return Preset.fromJson(responseData);
  }

  Future<void> deletePreset(int id) async {
    await _apiClient.delete('/api/presets/$id');
  }
}


