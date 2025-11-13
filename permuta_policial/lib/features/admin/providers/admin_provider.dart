// /lib/features/admin/providers/admin_provider.dart

import 'package:flutter/material.dart';
import '../../../core/api/repositories/admin_repository.dart';
import '../../../core/api/repositories/parceiros_repository.dart';
import '../../../core/api/api_exception.dart';

class AdminProvider with ChangeNotifier {
  final AdminRepository _adminRepository;
  final ParceirosRepository _parceirosRepository;

  AdminProvider(this._adminRepository, this._parceirosRepository);

  // Estado
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _estatisticas;
  List<Map<String, dynamic>> _sugestoes = [];
  List<Map<String, dynamic>> _verificacoes = [];
  List<Map<String, dynamic>> _policiais = [];
  int _totalPoliciais = 0;
  List<dynamic> _parceiros = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get estatisticas => _estatisticas;
  List<Map<String, dynamic>> get sugestoes => _sugestoes;
  List<Map<String, dynamic>> get verificacoes => _verificacoes;
  List<Map<String, dynamic>> get policiais => _policiais;
  int get totalPoliciais => _totalPoliciais;
  List<dynamic> get parceiros => _parceiros;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> loadEstatisticas() async {
    _setLoading(true);
    _setError(null);
    try {
      _estatisticas = await _adminRepository.getEstatisticas();
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao carregar estatísticas.');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSugestoes() async {
    _setLoading(true);
    _setError(null);
    try {
      _sugestoes = await _adminRepository.getSugestoes();
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao carregar sugestões.');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> aprovarSugestao(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _adminRepository.aprovarSugestao(id);
      await loadSugestoes();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao aprovar sugestão.');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejeitarSugestao(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _adminRepository.rejeitarSugestao(id);
      await loadSugestoes();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao rejeitar sugestão.');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadVerificacoes() async {
    _setLoading(true);
    _setError(null);
    try {
      _verificacoes = await _adminRepository.getVerificacoes();
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao carregar verificações.');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verificarPolicial(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _adminRepository.verificarPolicial(id);
      await loadVerificacoes();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao verificar policial.');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejeitarPolicial(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _adminRepository.rejeitarPolicial(id);
      await loadVerificacoes();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao rejeitar policial.');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPoliciais({String? search, String? status, int? forcaId, int offset = 0}) async {
    _setLoading(true);
    _setError(null);
    try {
      final result = await _adminRepository.getAllPoliciais(
        search: search,
        statusVerificacao: status,
        forcaId: forcaId,
        offset: offset,
      );
      _policiais = List<Map<String, dynamic>>.from(result['policiais'] ?? []);
      _totalPoliciais = result['total'] ?? 0;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao carregar policiais.');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updatePolicial(int id, Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      await _adminRepository.updatePolicial(id, data);
      await loadPoliciais();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao atualizar policial.');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadParceiros() async {
    _setLoading(true);
    _setError(null);
    try {
      _parceiros = await _parceirosRepository.getAll();
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao carregar parceiros.');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createParceiro(Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      await _parceirosRepository.create(data);
      await loadParceiros();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao criar parceiro.');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateParceiro(int id, Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      await _parceirosRepository.update(id, data);
      await loadParceiros();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao atualizar parceiro.');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteParceiro(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _parceirosRepository.delete(id);
      await loadParceiros();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao excluir parceiro.');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }
}

