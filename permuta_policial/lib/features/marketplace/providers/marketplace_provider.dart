// /lib/features/marketplace/providers/marketplace_provider.dart

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
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
    debugPrint('=== loadItens chamado ===');
    debugPrint('Tipo: $tipo, Search: $search');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getAll(tipo: tipo, search: search);
      debugPrint('loadItens: Recebidos ${result.length} itens');
      debugPrint('loadItens: Itens: $result');
      
      _itens = result;
      _errorMessage = null;
    } catch (e) {
      debugPrint('loadItens: ERRO - $e');
      if (e is ApiException && e.statusCode != 404) {
        _errorMessage = e.userMessage;
      } else {
        _errorMessage = null;
      }
      _itens = [];
    } finally {
      _isLoading = false;
      debugPrint('loadItens: Finalizado. Total de itens: ${_itens.length}');
      notifyListeners();
    }
  }

  Future<void> loadMeusItens(int policialId) async {
    debugPrint('=== loadMeusItens chamado ===');
    debugPrint('PolicialId: $policialId');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getByUsuario(policialId);
      debugPrint('loadMeusItens: Recebidos ${result.length} itens');
      debugPrint('loadMeusItens: Itens: $result');
      
      _meusItens = result;
      _errorMessage = null;
    } catch (e) {
      debugPrint('loadMeusItens: ERRO - $e');
      if (e is ApiException && e.statusCode != 404) {
        _errorMessage = e.userMessage;
      } else {
        _errorMessage = null;
      }
      _meusItens = [];
    } finally {
      _isLoading = false;
      debugPrint('loadMeusItens: Finalizado. Total de itens: ${_meusItens.length}');
      notifyListeners();
    }
  }

  Future<bool> createItem({
    required String titulo,
    required String descricao,
    required double valor,
    required String tipo,
    required List<File> fotos,
    List<XFile>? fotosXFile,
  }) async {
    debugPrint('=== createItem chamado ===');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.create(
        titulo: titulo,
        descricao: descricao,
        valor: valor,
        tipo: tipo,
        fotos: fotosXFile == null ? fotos : null,
        fotosXFile: fotosXFile,
      );
      
      debugPrint('createItem: Item criado com sucesso - ID: ${result.id}');
      _errorMessage = null;
      return true;
    } catch (e) {
      debugPrint('createItem: ERRO - $e');
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
    List<XFile>? fotosXFile,
  }) async {
    debugPrint('=== updateItem chamado ===');
    debugPrint('ID: $id');
    
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
        fotos: fotosXFile == null ? fotos : null,
        fotosXFile: fotosXFile,
      );
      
      debugPrint('updateItem: Item atualizado com sucesso');
      _errorMessage = null;
      return true;
    } catch (e) {
      debugPrint('updateItem: ERRO - $e');
      _errorMessage = e is ApiException ? e.userMessage : 'Erro ao atualizar item.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteItem(int id) async {
    debugPrint('=== deleteItem chamado ===');
    debugPrint('ID: $id');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.delete(id);
      debugPrint('deleteItem: Item excluído com sucesso');
      _errorMessage = null;
      return true;
    } catch (e) {
      debugPrint('deleteItem: ERRO - $e');
      _errorMessage = e is ApiException ? e.userMessage : 'Erro ao excluir item.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Métodos de admin
  Future<void> loadItensAdmin({String? status}) async {
    debugPrint('=== loadItensAdmin chamado ===');
    debugPrint('Status: $status');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getAllAdmin(status: status);
      debugPrint('loadItensAdmin: Recebidos ${result.length} itens');
      debugPrint('loadItensAdmin: Itens: $result');
      
      _itensAdmin = result;
      _errorMessage = null;
    } catch (e) {
      debugPrint('loadItensAdmin: ERRO - $e');
      _errorMessage = e is ApiException ? e.userMessage : 'Erro ao carregar itens.';
      _itensAdmin = [];
    } finally {
      _isLoading = false;
      debugPrint('loadItensAdmin: Finalizado. Total de itens: ${_itensAdmin.length}');
      notifyListeners();
    }
  }

  Future<bool> aprovarItem(int id) async {
    debugPrint('=== aprovarItem chamado ===');
    debugPrint('ID: $id');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.aprovar(id);
      debugPrint('aprovarItem: Item aprovado com sucesso');
      _errorMessage = null;
      return true;
    } catch (e) {
      debugPrint('aprovarItem: ERRO - $e');
      _errorMessage = e is ApiException ? e.userMessage : 'Erro ao aprovar item.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejeitarItem(int id) async {
    debugPrint('=== rejeitarItem chamado ===');
    debugPrint('ID: $id');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.rejeitar(id);
      debugPrint('rejeitarItem: Item rejeitado com sucesso');
      _errorMessage = null;
      return true;
    } catch (e) {
      debugPrint('rejeitarItem: ERRO - $e');
      _errorMessage = e is ApiException ? e.userMessage : 'Erro ao rejeitar item.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteItemAdmin(int id) async {
    debugPrint('=== deleteItemAdmin chamado ===');
    debugPrint('ID: $id');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteAdmin(id);
      debugPrint('deleteItemAdmin: Item excluído com sucesso');
      _errorMessage = null;
      return true;
    } catch (e) {
      debugPrint('deleteItemAdmin: ERRO - $e');
      _errorMessage = e is ApiException ? e.userMessage : 'Erro ao excluir item.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}