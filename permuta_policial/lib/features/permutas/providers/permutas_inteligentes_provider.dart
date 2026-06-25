import 'package:flutter/material.dart';

import '../../../core/api/repositories/permutas_inteligentes_repository.dart';
import '../../../core/models/smart_match_results.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/services/analytics_service.dart';

/// Provider isolado do motor experimental — não compartilha estado com DashboardProvider.matches
class PermutasInteligentesProvider with ChangeNotifier {
  final PermutasInteligentesRepository _repository;
  final AnalyticsService _analyticsService;

  bool _isLoading = false;
  bool _isLoadingSummary = false;
  String? _error;
  SmartMatchResults? _results;
  int? _summaryCount;

  PermutasInteligentesProvider(this._repository, this._analyticsService);

  bool get isLoading => _isLoading;
  bool get isLoadingSummary => _isLoadingSummary;
  String? get error => _error;
  SmartMatchResults? get results => _results;
  int? get summaryCount => _summaryCount;

  Future<void> fetchSummary() async {
    _isLoadingSummary = true;
    notifyListeners();
    try {
      _summaryCount = await _repository.getSummaryCount();
    } catch (_) {
      _summaryCount = null;
    }
    _isLoadingSummary = false;
    notifyListeners();
  }

  Future<void> fetchMatches({bool refresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _results = await _repository.getMatches(refresh: refresh);
      _summaryCount = _results?.totalMatches;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      await ErrorHandler.trackError(
        _analyticsService,
        e,
        endpoint: '/api/permutas-inteligentes/matches',
        method: 'GET',
      );
    }

    _isLoading = false;
    notifyListeners();
  }
}
