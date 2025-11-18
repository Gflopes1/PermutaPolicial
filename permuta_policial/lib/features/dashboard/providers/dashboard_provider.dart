// /lib/features/dashboard/providers/dashboard_provider.dart

import 'package:flutter/material.dart';
import 'package:permuta_policial/core/api/repositories/parceiros_repository.dart';
import '../../../core/api/repositories/policiais_repository.dart';
import '../../../core/api/repositories/intencoes_repository.dart';
import '../../../core/api/repositories/permutas_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/intencao.dart';
import '../../../core/models/match_results.dart';
import '../../../core/api/api_exception.dart';

class DashboardProvider with ChangeNotifier {
  final PoliciaisRepository _policiaisRepository; 
  final IntencoesRepository _intencoesRepository;
  final PermutasRepository _permutasRepository;
  final StorageService _storageService;

  // --- MUDANÇA 1: SEPARAMOS OS ESTADOS DE LOADING E ERRO ---
  bool _isLoadingInitialData = true; // Para perfil e intenções
  bool _isLoadingMatches = false;      // Apenas para os matches
  String? _initialDataError;         // Erro dos dados iniciais
  String? _matchesError;             // Erro específico dos matches

  UserProfile? _userData;
  List<Intencao> _intencoes = [];
  FullMatchResults? _matches;
  List<dynamic> _parceiros = [];
  bool _exibirCardParceiros = false;

  final ParceirosRepository _parceirosRepository;

  DashboardProvider(
    this._policiaisRepository, 
    this._intencoesRepository, 
    this._permutasRepository, 
    this._storageService, 
    this._parceirosRepository,
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
      ]);

      _userData = results[0] as UserProfile?;
      final parceirosConfig = results[1] as Map<String, dynamic>;
      _exibirCardParceiros = true; // Sempre exibe o card
      _parceiros = parceirosConfig['parceiros'] ?? [];

      if (_userData?.unidadeAtualNome != null) {
        _intencoes = await _intencoesRepository.getMyIntentions();
        // Dispara a busca por matches, mas NÃO espera por ela.
        fetchMatches(); 
      }
    } catch (e) {
      if (e is ApiException) {
        _initialDataError = e.userMessage;
      } else {
        _initialDataError = 'Erro ao carregar dados. Tente novamente.';
      }
    }
    
    _isLoadingInitialData = false;
    notifyListeners();
  }

  /// MUDANÇA 3: Nova função isolada apenas para buscar os matches.
  Future<void> fetchMatches() async {
    // Não busca se o perfil estiver incompleto.
    if (_userData?.unidadeAtualNome == null) return;

    _isLoadingMatches = true;
    _matchesError = null;
    notifyListeners();

    try {
      _matches = await _permutasRepository.getMatches();
    } catch (e) {
      if (e is ApiException) {
        _matchesError = e.userMessage;
      } else {
        _matchesError = 'Erro ao buscar combinações. Tente novamente.';
      }
    }

    _isLoadingMatches = false;
    notifyListeners();
  }
  
  // As funções de update agora chamam fetchInitialData
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
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateIntencoes(List<Map<String, dynamic>> intencoes) async {
    try {
      await _intencoesRepository.updateMyIntentions(intencoes);
      await fetchInitialData();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _initialDataError = e.userMessage;
      } else {
        _initialDataError = 'Erro ao salvar intenções. Tente novamente.';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteIntencoes() async {
    try {
      await _intencoesRepository.deleteMyIntentions();
      await fetchInitialData();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _initialDataError = e.userMessage;
      } else {
        _initialDataError = 'Erro ao excluir intenções. Tente novamente.';
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storageService.deleteToken();
  }
}