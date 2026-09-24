import '../api_client.dart';
import '../../models/smart_match_results.dart';

class PermutasInteligentesRepository {
  final ApiClient _apiClient;

  PermutasInteligentesRepository(this._apiClient);

  Future<SmartMatchResults> getMatches({bool refresh = false}) async {
    final query = refresh ? '?refresh=1' : '';
    final responseData =
        await _apiClient.get('/api/permutas-inteligentes/matches$query');
    return SmartMatchResults.fromJson(responseData);
  }

  Future<int> getSummaryCount() async {
    final responseData =
        await _apiClient.get('/api/permutas-inteligentes/summary');
    return (responseData['total_matches'] as num?)?.toInt() ?? 0;
  }
}
