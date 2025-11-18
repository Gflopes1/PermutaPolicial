// /lib/features/notificacoes/providers/notificacoes_provider.dart

import 'package:flutter/foundation.dart';
import '../../../core/api/repositories/notificacoes_repository.dart';
import '../../../core/models/notificacao.dart';

class NotificacoesProvider with ChangeNotifier {
  final NotificacoesRepository _repository;

  NotificacoesProvider(this._repository);

  List<Notificacao> _notificacoes = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _countNaoLidas = 0;

  List<Notificacao> get notificacoes => _notificacoes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get countNaoLidas => _countNaoLidas;

  Future<void> loadNotificacoes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notificacoes = await _repository.getNotificacoes();
      _countNaoLidas = await _repository.countNaoLidas();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCount() async {
    try {
      _countNaoLidas = await _repository.countNaoLidas();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao atualizar contador de notificações: $e');
    }
  }

  Future<bool> criarSolicitacaoContato(int destinatarioId) async {
    try {
      await _repository.criarSolicitacaoContato(destinatarioId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> responderSolicitacaoContato(int notificacaoId, bool aceitar) async {
    try {
      await _repository.responderSolicitacaoContato(notificacaoId, aceitar);
      await loadNotificacoes(); // Recarrega para atualizar a lista
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> marcarComoLida(int id) async {
    try {
      await _repository.marcarComoLida(id);
      await loadNotificacoes();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> marcarTodasComoLidas() async {
    try {
      await _repository.marcarTodasComoLidas();
      await loadNotificacoes();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.delete(id);
      await loadNotificacoes();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}

