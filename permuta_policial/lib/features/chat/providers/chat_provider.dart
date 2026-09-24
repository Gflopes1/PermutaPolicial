// /lib/features/chat/providers/chat_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/api/repositories/chat_repository.dart';
import '../../../core/services/socket_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatRepository _chatRepository;
  final SocketService _socketService;

  ChatProvider(this._chatRepository, this._socketService);

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _conversas = [];
  List<dynamic> _mensagens = [];
  Map<String, dynamic>? _conversaAtual;
  int _mensagensNaoLidas = 0;
  bool _isTyping = false;
  String? _typingUser;
  bool _isSending = false;
  bool _listenersSetup = false;
  Timer? _conversasDebounce;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get conversas => _conversas;
  List<dynamic> get mensagens => _mensagens;
  Map<String, dynamic>? get conversaAtual => _conversaAtual;
  int get mensagensNaoLidas => _mensagensNaoLidas;
  bool get isTyping => _isTyping;
  String? get typingUser => _typingUser;

  Future<void> initializeSocket() async {
    try {
      await _socketService.connect();
      if (!_listenersSetup) {
        _setupSocketListeners();
        _listenersSetup = true;
      }
    } catch (e) {
      _errorMessage = 'Erro ao conectar ao chat: ${e.toString()}';
      notifyListeners();
    }
  }

  int? _conversaId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  void _setupSocketListeners() {
    _socketService.onMensagemRecebida((mensagem) {
      final conversaId = _conversaId(mensagem['conversa_id']);
      final atualId = _conversaId(_conversaAtual?['id']);
      if (atualId != null && conversaId == atualId) {
        _upsertMensagem(mensagem, removePending: true);
      }
      _scheduleConversasRefresh();
    });

    _socketService.onNovaMensagemNotificacao((_) {
      _scheduleConversasRefresh();
      loadMensagensNaoLidas();
    });

    _socketService.onUserTyping((data) {
      if (data['conversaId'] == _conversaAtual?['id']) {
        _isTyping = true;
        _typingUser = data['usuarioNome'];
        notifyListeners();
      }
    });

    _socketService.onUserStopTyping((data) {
      if (data['conversaId'] == _conversaAtual?['id']) {
        _isTyping = false;
        _typingUser = null;
        notifyListeners();
      }
    });
  }

  void _scheduleConversasRefresh() {
    _conversasDebounce?.cancel();
    _conversasDebounce = Timer(const Duration(milliseconds: 800), () {
      _refreshConversasSilencioso();
    });
  }

  Future<void> _refreshConversasSilencioso() async {
    try {
      _conversas = await _chatRepository.getConversas();
      notifyListeners();
    } catch (_) {
      // Ignora erros em refresh em background
    }
  }

  Future<void> loadConversas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _conversas = await _chatRepository.getConversas();
    } catch (e) {
      _errorMessage = 'Erro ao carregar conversas: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMensagens(int conversaId, {bool refresh = false}) async {
    if (!refresh) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final conversa = await _chatRepository.getConversa(conversaId);
      _conversaAtual = conversa;

      await _socketService.connect();
      _socketService.joinConversa(conversaId);

      _mensagens = await _chatRepository.getMensagens(conversaId);
      _dedupeMensagens();

      await _chatRepository.marcarComoLidas(conversaId);
      if (_socketService.isConnected) {
        _socketService.marcarLidas(conversaId);
      }

      await loadMensagensNaoLidas();
    } catch (e) {
      _errorMessage = 'Erro ao carregar mensagens: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendMensagem(String mensagem, {int? remetenteId}) async {
    if (_conversaAtual == null || mensagem.trim().isEmpty || _isSending) {
      return false;
    }

    final conversaId = _conversaAtual!['id'] as int;
    final texto = mensagem.trim();
    _isSending = true;

    final pendingMessage = {
      'id': -DateTime.now().millisecondsSinceEpoch,
      'conversa_id': conversaId,
      'mensagem': texto,
      'pending': true,
      'remetente_id': remetenteId,
      'criado_em': DateTime.now().toIso8601String(),
    };
    _mensagens.add(pendingMessage);
    notifyListeners();

    try {
      // Sempre persiste via REST — garante notificação/push mesmo sem Socket.IO (ex.: Passenger).
      final criada = await _chatRepository.createMensagem(conversaId, texto);
      _mensagens.removeWhere((m) => m['pending'] == true);
      _upsertMensagem(criada);
      _scheduleConversasRefresh();
      return true;
    } catch (e) {
      _mensagens.removeWhere((m) => m['pending'] == true);
      _errorMessage = 'Erro ao enviar mensagem: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isSending = false;
    }
  }

  Future<Map<String, dynamic>?> iniciarConversa(int usuarioId, {bool anonima = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final conversa = await _chatRepository.iniciarConversa(usuarioId, anonima: anonima);
      await loadConversas();
      _isLoading = false;
      notifyListeners();
      return conversa;
    } catch (e) {
      _errorMessage = 'Erro ao iniciar conversa: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadMensagensNaoLidas() async {
    try {
      _mensagensNaoLidas = await _chatRepository.getMensagensNaoLidas();
      notifyListeners();
    } catch (_) {}
  }

  void startTyping() {
    if (_conversaAtual != null && _socketService.isConnected) {
      _socketService.typing(_conversaAtual!['id']);
    }
  }

  void stopTyping() {
    if (_conversaAtual != null && _socketService.isConnected) {
      _socketService.stopTyping(_conversaAtual!['id']);
    }
  }

  void leaveConversa() {
    if (_conversaAtual != null) {
      _socketService.leaveConversa(_conversaAtual!['id']);
      _conversaAtual = null;
      _mensagens = [];
      _isTyping = false;
      _typingUser = null;
      notifyListeners();
    }
  }

  Future<void> excluirConversa(int conversaId) async {
    try {
      await _chatRepository.excluirConversa(conversaId);
      _conversas.removeWhere((c) => c['id'] == conversaId);
      if (_conversaAtual?['id'] == conversaId) {
        _conversaAtual = null;
        _mensagens = [];
      }
      notifyListeners();
      await loadMensagensNaoLidas();
    } catch (e) {
      _errorMessage = 'Erro ao excluir conversa: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> aceitarCompartilharDados(int conversaId) async {
    try {
      await _chatRepository.aceitarCompartilharDados(conversaId);
      await loadMensagens(conversaId, refresh: true);
      await loadConversas();
    } catch (e) {
      _errorMessage = 'Erro ao compartilhar dados: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  int? _messageId(dynamic id) {
    if (id == null) return null;
    if (id is int) return id;
    return int.tryParse(id.toString());
  }

  String _mensagemDedupeKey(dynamic m) {
    final id = _messageId(m['id']);
    if (id != null && id > 0) return 'id:$id';
    final texto = (m['mensagem'] ?? '').toString().trim();
    final remetente = m['remetente_id']?.toString() ?? '';
    final criado = (m['criado_em'] ?? '').toString();
    return 'tmp:$remetente:$texto:$criado';
  }

  void _dedupeMensagens() {
    final seen = <String>{};
    final deduped = <dynamic>[];
    for (final m in _mensagens) {
      final key = _mensagemDedupeKey(m);
      if (seen.add(key)) deduped.add(m);
    }
    _mensagens = deduped;
  }

  void _upsertMensagem(Map<String, dynamic> mensagem, {bool removePending = false}) {
    if (removePending) {
      _mensagens.removeWhere((m) => m['pending'] == true);
    }
    final id = _messageId(mensagem['id']);
    if (id != null && id > 0) {
      _mensagens.removeWhere((m) => _messageId(m['id']) == id);
    } else {
      final texto = (mensagem['mensagem'] ?? '').toString().trim();
      final remetente = mensagem['remetente_id'];
      _mensagens.removeWhere((m) {
        if (m['pending'] != true) return false;
        return m['mensagem']?.toString().trim() == texto &&
            m['remetente_id']?.toString() == remetente?.toString();
      });
    }
    _mensagens.add(mensagem);
    _dedupeMensagens();
    notifyListeners();
  }

  @override
  void dispose() {
    _conversasDebounce?.cancel();
    super.dispose();
  }
}
