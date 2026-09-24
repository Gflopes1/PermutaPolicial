// /lib/features/notificacoes/providers/notificacoes_provider.dart

import 'package:flutter/foundation.dart';
import '../../../core/api/repositories/notificacoes_repository.dart';
import '../../../core/models/notificacao.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/services/socket_service.dart';

class NotificacoesProvider with ChangeNotifier {
  final NotificacoesRepository _repository;

  NotificacoesProvider(this._repository);

  List<Notificacao> _notificacoes = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _countNaoLidas = 0;
  bool _isDuplicate = false; // Flag para indicar se foi um caso de duplicata

  List<Notificacao> get notificacoes => _notificacoes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get countNaoLidas => _countNaoLidas;
  bool get isDuplicate => _isDuplicate; // Getter para verificar se foi duplicata

  bool _socketBound = false;

  /// Atualiza contador quando chega evento realtime (chat, etc.).
  void bindSocketRefresh(SocketService socketService) {
    if (_socketBound) return;
    _socketBound = true;
    socketService.onNovaMensagemNotificacao((_) {
      refreshCount();
    });
  }

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

  Future<bool> criarSolicitacaoContato(int destinatarioId, {String? origem, String? tipoPermuta}) async {
    _isDuplicate = false; // Reset flag
    try {
      final result = await _repository.criarSolicitacaoContato(
        destinatarioId, 
        origem: origem,
        tipoPermuta: tipoPermuta,
      );
      // ✅ CORREÇÃO: Verifica se a resposta indica que já existia (already_exists: true)
      if (result['already_exists'] == true) {
        _isDuplicate = true;
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      // ✅ CORREÇÃO: Se o código for DUPLICATE, trata como sucesso (já existe solicitação pendente)
      // Isso é um fallback caso o backend ainda retorne erro DUPLICATE em algum caso
      if (e is ApiException && e.code == 'DUPLICATE') {
        _isDuplicate = true; // Marca como duplicata
        _errorMessage = null; // Limpa erro pois é um caso de sucesso
        notifyListeners();
        return true; // Retorna true para indicar sucesso
      }
      _isDuplicate = false;
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

