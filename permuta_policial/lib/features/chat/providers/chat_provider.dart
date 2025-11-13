// /lib/features/chat/providers/chat_provider.dart

import 'package:flutter/material.dart';
import '../../../core/api/repositories/chat_repository.dart';
import '../../../core/services/socket_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatRepository _chatRepository;
  final SocketService _socketService;

  ChatProvider(this._chatRepository, this._socketService);

  // Estado
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _conversas = [];
  List<dynamic> _mensagens = [];
  Map<String, dynamic>? _conversaAtual;
  int _mensagensNaoLidas = 0;
  bool _isTyping = false;
  String? _typingUser;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get conversas => _conversas;
  List<dynamic> get mensagens => _mensagens;
  Map<String, dynamic>? get conversaAtual => _conversaAtual;
  int get mensagensNaoLidas => _mensagensNaoLidas;
  bool get isTyping => _isTyping;
  String? get typingUser => _typingUser;

  // Inicializa o socket
  Future<void> initializeSocket() async {
    try {
      await _socketService.connect();
      _setupSocketListeners();
    } catch (e) {
      _errorMessage = 'Erro ao conectar ao chat: ${e.toString()}';
      notifyListeners();
    }
  }

  void _setupSocketListeners() {
    _socketService.onMensagemRecebida((mensagem) {
      if (_conversaAtual != null && mensagem['conversa_id'] == _conversaAtual!['id']) {
        _mensagens.add(mensagem);
        notifyListeners();
      }
      // Atualiza a lista de conversas
      loadConversas();
    });

    _socketService.onNovaMensagemNotificacao((data) {
      loadConversas();
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

  // Carrega todas as conversas
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

  // Carrega mensagens de uma conversa
  Future<void> loadMensagens(int conversaId, {bool refresh = false}) async {
    if (!refresh) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final conversa = await _chatRepository.getConversa(conversaId);
      _conversaAtual = conversa;

      // Entra na sala do socket
      _socketService.joinConversa(conversaId);

      // Carrega mensagens
      _mensagens = await _chatRepository.getMensagens(conversaId);

      // Marca como lidas
      await _chatRepository.marcarComoLidas(conversaId);
      _socketService.marcarLidas(conversaId);

      // Atualiza contador
      await loadMensagensNaoLidas();
    } catch (e) {
      _errorMessage = 'Erro ao carregar mensagens: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Envia uma mensagem
  Future<bool> sendMensagem(String mensagem) async {
    if (_conversaAtual == null || mensagem.trim().isEmpty) {
      return false;
    }

    try {
      // Envia via socket (que também salva no banco)
      _socketService.sendMensagem(_conversaAtual!['id'], mensagem.trim());

      // Opcionalmente, também salva via API para garantir
      await _chatRepository.createMensagem(_conversaAtual!['id'], mensagem.trim());

      return true;
    } catch (e) {
      _errorMessage = 'Erro ao enviar mensagem: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Inicia uma nova conversa
  Future<Map<String, dynamic>?> iniciarConversa(int usuarioId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final conversa = await _chatRepository.iniciarConversa(usuarioId);
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

  // Carrega contador de mensagens não lidas
  Future<void> loadMensagensNaoLidas() async {
    try {
      _mensagensNaoLidas = await _chatRepository.getMensagensNaoLidas();
      notifyListeners();
    } catch (e) {
      // Ignora erros silenciosamente
    }
  }

  // Indicar que está digitando
  void startTyping() {
    if (_conversaAtual != null) {
      _socketService.typing(_conversaAtual!['id']);
    }
  }

  // Parar de digitar
  void stopTyping() {
    if (_conversaAtual != null) {
      _socketService.stopTyping(_conversaAtual!['id']);
    }
  }

  // Sair da conversa atual
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

  // Limpar estado
  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}

