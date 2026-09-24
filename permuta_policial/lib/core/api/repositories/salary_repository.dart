// /lib/core/api/repositories/salary_repository.dart

import '../api_client.dart';
import '../../models/salary.dart';

class SalaryRepository {
  final ApiClient _apiClient;

  SalaryRepository(this._apiClient);

  Future<SalarySettings> getSettings() async {
    final responseData = await _apiClient.get('/api/salary/settings');
    return SalarySettings.fromJson(responseData);
  }

  Future<SalarySettings> updateSettings(SalarySettings settings) async {
    final responseData = await _apiClient.put(
      '/api/salary/settings',
      settings.toJson(includeId: false) // Não envia id no update
    );
    return SalarySettings.fromJson(responseData);
  }

  Future<Map<String, dynamic>> previewMonth(int month, int year) async {
    return await _apiClient.get(
      '/api/salary/preview?month=$month&year=$year'
    ) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateMonth(int month, int year) async {
    return await _apiClient.post(
      '/api/salary/generate?month=$month&year=$year',
      {}
    ) as Map<String, dynamic>;
  }

  Future<SalaryResult?> getResult(int month, int year) async {
    try {
      final responseData = await _apiClient.get(
        '/api/salary/result?month=$month&year=$year'
      );
      return responseData != null ? SalaryResult.fromJson(responseData) : null;
    } catch (e) {
      return null;
    }
  }

  Future<List<SalaryResult>> getAllResults({int limit = 12}) async {
    final responseData = await _apiClient.get('/api/salary/results?limit=$limit');
    return (responseData as List)
        .map((json) => SalaryResult.fromJson(json))
        .toList();
  }

  Future<void> exportMonth(int month, int year, {String format = 'pdf'}) async {
    // Por enquanto, apenas faz a requisição (PDF será implementado depois)
    await _apiClient.get(
      '/api/salary/export?month=$month&year=$year&format=$format'
    );
  }
}

