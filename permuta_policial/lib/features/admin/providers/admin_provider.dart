// /lib/features/admin/providers/admin_provider.dart

import 'package:flutter/foundation.dart';
import '../../../core/api/repositories/admin_repository.dart';
import '../../../core/models/policial_admin.dart';
import '../../../core/models/parceiro.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository;

  AdminProvider(this._repository);

  // Estado
  bool _isLoading = false;
  String? _errorMessage;

  // Estatísticas
  Map<String, dynamic>? _estatisticas;

  // Usuários
  List<PolicialAdmin> _policiais = [];
  int _totalPoliciais = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  String _searchQuery = '';

  // Verificações
  List<dynamic> _verificacoes = [];

  // Sugestões
  List<dynamic> _sugestoes = [];

  // Parceiros
  List<Parceiro> _parceiros = [];
  bool _exibirCardParceiros = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get estatisticas => _estatisticas;
  List<PolicialAdmin> get policiais => _policiais;
  int get totalPoliciais => _totalPoliciais;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String get searchQuery => _searchQuery;
  List<dynamic> get verificacoes => _verificacoes;
  List<dynamic> get sugestoes => _sugestoes;
  List<Parceiro> get parceiros => _parceiros;
  bool get exibirCardParceiros => _exibirCardParceiros;

  // Carregar estatísticas
  Future<void> loadEstatisticas() async {
    _setLoading(true);
    try {
      _estatisticas = await _repository.getEstatisticas();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Carregar usuários
  Future<void> loadPoliciais({int page = 1, String search = ''}) async {
    _setLoading(true);
    try {
      final result = await _repository.getAllPoliciais(
        page: page,
        limit: 50,
        search: search,
      );
      _policiais = (result['policiais'] as List)
          .map((json) => PolicialAdmin.fromJson(json))
          .toList();
      _totalPoliciais = result['total'] as int;
      _currentPage = result['page'] as int;
      _totalPages = result['totalPages'] as int;
      _searchQuery = search;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Carregar verificações
  Future<void> loadVerificacoes() async {
    _setLoading(true);
    try {
      _verificacoes = await _repository.getVerificacoes();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verificarPolicial(int policialId) async {
    try {
      await _repository.verificarPolicial(policialId);
      await loadVerificacoes();
      await loadPoliciais(page: _currentPage, search: _searchQuery);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> rejeitarPolicial(int policialId) async {
    try {
      await _repository.rejeitarPolicial(policialId);
      await loadVerificacoes();
      await loadPoliciais(page: _currentPage, search: _searchQuery);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Carregar sugestões
  Future<void> loadSugestoes() async {
    _setLoading(true);
    try {
      _sugestoes = await _repository.getSugestoes();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> aprovarSugestao(int sugestaoId) async {
    try {
      await _repository.aprovarSugestao(sugestaoId);
      await loadSugestoes();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> rejeitarSugestao(int sugestaoId) async {
    try {
      await _repository.rejeitarSugestao(sugestaoId);
      await loadSugestoes();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Carregar parceiros
  Future<void> loadParceiros() async {
    _setLoading(true);
    try {
      _parceiros = await _repository.getAllParceiros();
      final config = await _repository.getParceirosConfig();
      _exibirCardParceiros = config['exibir_card'] as bool? ?? false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createParceiro(Parceiro parceiro) async {
    try {
      await _repository.createParceiro(parceiro.toJson());
      await loadParceiros();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateParceiro(int id, Parceiro parceiro) async {
    try {
      await _repository.updateParceiro(id, parceiro.toJson());
      await loadParceiros();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteParceiro(int id) async {
    try {
      await _repository.deleteParceiro(id);
      await loadParceiros();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateParceirosConfig(bool exibirCard) async {
    try {
      await _repository.updateParceirosConfig(exibirCard);
      _exibirCardParceiros = exibirCard;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

