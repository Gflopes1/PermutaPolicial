// /lib/core/api/repositories/work_repository.dart

import '../api_client.dart';
import '../../models/work_day.dart';

class WorkRepository {
  final ApiClient _apiClient;

  WorkRepository(this._apiClient);

  Future<List<WorkDay>> getMonthDays(int month, int year) async {
    final responseData = await _apiClient.get(
      '/api/work/month?month=$month&year=$year'
    );
    return (responseData as List)
        .map((json) => WorkDay.fromJson(json))
        .toList();
  }

  Future<int> upsertDay(WorkDay day) async {
    final responseData = await _apiClient.post('/api/work/day', day.toJson());
    if (responseData is Map && responseData['id'] != null) {
      return responseData['id'] as int;
    }
    return responseData is int ? responseData : day.id ?? 0;
  }

  Future<void> deleteDay(int dayId) async {
    await _apiClient.delete('/api/work/day/$dayId');
  }

  Future<void> applyPreset(List<String> dates, int presetId) async {
    await _apiClient.post(
      '/api/work/apply-preset',
      {'dates': dates, 'preset_id': presetId},
    );
  }

  Future<Map<String, dynamic>> getMonthStats(int month, int year) async {
    return await _apiClient.get(
      '/api/work/stats?month=$month&year=$year'
    ) as Map<String, dynamic>;
  }
}

