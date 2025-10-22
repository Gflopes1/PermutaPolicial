// /lib/features/profile/providers/profile_provider.dart

import 'package:flutter/material.dart';
import '../../../core/api/repositories/policiais_repository.dart';
import '../../../core/api/repositories/dados_repository.dart';
import '../../../core/models/user_profile.dart';

class ProfileProvider with ChangeNotifier {
  final PoliciaisRepository _policiaisRepository;
  final DadosRepository _dadosRepository;

  ProfileProvider(this._policiaisRepository, this._dadosRepository);

  bool _isLoading = true;
  String? _errorMessage;
  UserProfile? _userProfile;

  // Getters para a UI
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserProfile? get userProfile => _userProfile;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _userProfile = await _policiaisRepository.getMyProfile();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _policiaisRepository.updateMyProfile(data);
      await loadProfile(); 
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Funções de busca para os Dropdowns ---

  // ADICIONADO: Função para buscar as forças policiais
  Future<List<dynamic>> getForcas() {
    return _dadosRepository.getForcas();
  }

  Future<List<dynamic>> getEstados() {
    return _dadosRepository.getEstados();
  }

  Future<List<dynamic>> getMunicipios(int estadoId) {
    return _dadosRepository.getMunicipiosPorEstado(estadoId);
  }

  Future<List<dynamic>> getUnidades({required int municipioId, required int forcaId}) {
    return _dadosRepository.getUnidades(municipioId: municipioId, forcaId: forcaId);
  }
}