// /lib/features/dashboard/providers/dashboard_provider.dart

import 'package:flutter/material.dart';
import 'package:permuta_policial/core/api/repositories/parceiros_repository.dart';
import '../../../core/api/repositories/consultoria_juridica_repository.dart';
import '../../../core/models/consultoria_advogado.dart';
import '../../../core/api/repositories/policiais_repository.dart';
import '../../../core/api/repositories/intencoes_repository.dart';
import '../../../core/api/repositories/permutas_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/intencao.dart';
import '../../../core/models/match_results.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/services/analytics_service.dart';

class DashboardProvider with ChangeNotifier {
  final PoliciaisRepository _policiaisRepository; 
  final IntencoesRepository _intencoesRepository;
  final PermutasRepository _permutasRepository;
  final StorageService _storageService;
  final AnalyticsService _analyticsService;

  // --- MUDANÇA 1: SEPARAMOS OS ESTADOS DE LOADING E ERRO ---
  bool _isLoadingInitialData = true; // Para perfil e intenções
  bool _isLoadingMatches = false;      // Apenas para os matches
  String? _initialDataError;         // Erro dos dados iniciais
  String? _matchesError;             // Erro específico dos matches

  UserProfile? _userData;
  List<Intencao> _intencoes = [];
  FullMatchResults? _matches;
  List<dynamic> _parceiros = [];
  List<ConsultoriaAdvogado> _consultoriaAdvogados = [];
  bool _exibirCardParceiros = false;

  final ParceirosRepository _parceirosRepository;
  final ConsultoriaJuridicaRepository _consultoriaRepository;

  DashboardProvider(
    this._policiaisRepository, 
    this._intencoesRepository, 
    this._permutasRepository, 
    this._storageService, 
    this._parceirosRepository,
    this._consultoriaRepository,
    this._analyticsService,
  );

  // Getters atualizados
  bool get isLoadingInitialData => _isLoadingInitialData;
  bool get isLoadingMatches => _isLoadingMatches;
  String? get initialDataError => _initialDataError;
  String? get matchesError => _matchesError;
  UserProfile? get userData => _userData;
  List<Intencao> get intencoes => _intencoes;
  FullMatchResults? get matches => _matches;
  List<dynamic> get parceiros => _parceiros;
  List<ConsultoriaAdvogado> get consultoriaAdvogados => _consultoriaAdvogados;
  bool get exibirCardParceiros => _exibirCardParceiros;

  /// MUDANÇA 2: Renomeado para buscar apenas os dados essenciais.
  Future<void> fetchInitialData() async {
    _isLoadingInitialData = true;
    _initialDataError = null;
    notifyListeners();

    try {
      // Busca dados em paralelo
      final results = await Future.wait([
        _policiaisRepository.getMyProfile(),
        _parceirosRepository.getParceirosConfig(),
        _consultoriaRepository.getPublicList().catchError((_) => <ConsultoriaAdvogado>[]),
      ]);

      _userData = results[0] as UserProfile?;
      final parceirosConfig = results[1] as Map<String, dynamic>;
      _exibirCardParceiros = true; // Sempre exibe o card
      _parceiros = parceirosConfig['parceiros'] ?? [];
      _consultoriaAdvogados = results[2] as List<ConsultoriaAdvogado>;

      // Carrega intenções se tiver unidade OU município definido
      if (_userData?.unidadeAtualNome != null || _userData?.municipioAtualNome != null) {
        _intencoes = await _intencoesRepository.getMyIntentions();
        // Dispara a busca por matches, mas NÃO espera por ela.
        fetchMatches(); 
      }
    } catch (e) {
      _initialDataError = ErrorHandler.getErrorMessage(e);
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/policiais/me', method: 'GET');
    }
    
    _isLoadingInitialData = false;
    notifyListeners();
  }

  /// MUDANÇA 3: Nova função isolada apenas para buscar os matches.
  Future<void> fetchMatches() async {
    // Não busca se o perfil estiver incompleto (sem unidade e sem município).
    if (_userData?.unidadeAtualNome == null && _userData?.municipioAtualNome == null) return;

    _isLoadingMatches = true;
    _matchesError = null;
    notifyListeners();

    try {
      _matches = await _permutasRepository.getMatches();
    } catch (e) {
      _matchesError = ErrorHandler.getErrorMessage(e);
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/permutas/matches', method: 'GET');
    }

    _isLoadingMatches = false;
    notifyListeners();
  }

  /// Recarrega intenções e matches sem buscar parceiros/perfil completo.
  Future<void> refreshPermutasData() async {
    if (_userData == null) {
      await fetchInitialData();
      return;
    }
    if (_userData?.unidadeAtualNome == null &&
        _userData?.municipioAtualNome == null) {
      return;
    }
    try {
      _intencoes = await _intencoesRepository.getMyIntentions();
      await fetchMatches();
    } catch (e) {
      _matchesError = ErrorHandler.getErrorMessage(e);
      notifyListeners();
    }
  }

  Future<void> _refreshAfterIntencoesMutation() async {
    try {
      if (_userData?.unidadeAtualNome != null ||
          _userData?.municipioAtualNome != null) {
        _intencoes = await _intencoesRepository.getMyIntentions();
        await fetchMatches();
      }
      notifyListeners();
    } catch (e) {
      _initialDataError = ErrorHandler.getErrorMessage(e);
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      await _policiaisRepository.updateMyProfile(data);
      await fetchInitialData();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _initialDataError = e.userMessage;
      } else {
        _initialDataError = 'Erro ao atualizar perfil. Tente novamente.';
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/policiais/me', method: 'PUT');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateIntencoes(List<Map<String, dynamic>> intencoes) async {
    try {
      await _intencoesRepository.updateMyIntentions(intencoes);
      await _refreshAfterIntencoesMutation();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _initialDataError = e.userMessage;
      } else {
        _initialDataError = 'Erro ao salvar intenções. Tente novamente.';
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/intencoes/me', method: 'PUT');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteIntencoes() async {
    try {
      await _intencoesRepository.deleteMyIntentions();
      await _refreshAfterIntencoesMutation();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _initialDataError = e.userMessage;
      } else {
        _initialDataError = 'Erro ao excluir intenções. Tente novamente.';
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/intencoes/me', method: 'DELETE');
      notifyListeners();
      return false;
    }
  }

  Future<bool> renewIntencoes() async {
    try {
      await _intencoesRepository.renewMyIntentions();
      await _refreshAfterIntencoesMutation();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _initialDataError = e.userMessage;
      } else {
        _initialDataError = 'Erro ao renovar intenções. Tente novamente.';
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/intencoes/me/renovar', method: 'POST');
      notifyListeners();
      return false;
    }
  }

  Future<bool> markPermutaConcluida() async {
    try {
      await _intencoesRepository.markPermutaConcluida();
      _intencoes = [];
      _matches = null;
      await fetchMatches();
      notifyListeners();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _initialDataError = e.userMessage;
      } else {
        _initialDataError = 'Erro ao registrar a permuta. Tente novamente.';
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/intencoes/me/consegui-permutar', method: 'POST');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storageService.deleteToken();
  }
}
