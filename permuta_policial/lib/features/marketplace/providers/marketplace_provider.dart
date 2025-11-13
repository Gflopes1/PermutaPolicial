// /lib/features/marketplace/providers/marketplace_provider.dart

import 'package:flutter/foundation.dart';
import '../../../core/api/repositories/marketplace_repository.dart';
import '../../../core/models/marketplace_item.dart';
import '../../../core/api/api_exception.dart';
import 'dart:io';

class MarketplaceProvider with ChangeNotifier {
  final MarketplaceRepository _repository;

  MarketplaceProvider(this._repository);

  List<MarketplaceItem> _itens = [];
  List<MarketplaceItem> _meusItens = [];
  List<MarketplaceItem> _itensAdmin = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MarketplaceItem> get itens => _itens;
  List<MarketplaceItem> get meusItens => _meusItens;
  List<MarketplaceItem> get itensAdmin => _itensAdmin;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadItens({String? tipo, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _itens = await _repository.getAll(tipo: tipo, search: search);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e is ApiException ? e.userMessage : 'Erro ao carregar itens.';
      _itens = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMeusItens(int policialId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _meusItens = await _repository.getByUsuario(policialId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e is ApiException ? e.userMessage : 'Erro ao carregar seus itens.';
      _meusItens = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createItem({
    required String titulo,
    required String descricao,
    required double valor,
    required String tipo,
    required List<File> fotos,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.create(
        titulo: titulo,
        descricao: descricao,
        valor: valor,
        tipo: tipo,
        fotos: fotos,
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.userMessage : 'Erro ao criar item.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateItem({
    required int id,
    String? titulo,
    String? descricao,
    double? valor,
    String? tipo,
    List<File>? fotos,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.update(
        id: id,
        titulo: titulo,
        descricao: descricao,
        valor: valor,
        tipo: tipo,
        fotos: fotos,
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.userMessage : 'Erro ao atualizar item.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteItem(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.delete(id);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.userMessage : 'Erro ao excluir item.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Métodos de admin
  Future<void> loadItensAdmin({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _itensAdmin = await _repository.getAllAdmin(status: status);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e is ApiException ? e.userMessage : 'Erro ao carregar itens.';
      _itensAdmin = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> aprovarItem(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.aprovar(id);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.userMessage : 'Erro ao aprovar item.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejeitarItem(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.rejeitar(id);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.userMessage : 'Erro ao rejeitar item.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteItemAdmin(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteAdmin(id);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.userMessage : 'Erro ao excluir item.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

