// /lib/core/services/socket_service.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../services/storage_service.dart';

class SocketService {
  io.Socket? _socket;
  final StorageService _storageService;
  final String _baseUrl = 'https://br.permutapolicial.com.br';

  SocketService(this._storageService);

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket?.connected ?? false) {
      return;
    }

    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Token não encontrado. Faça login novamente.');
    }

    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      developer.log('✅ Socket conectado', name: 'SocketService');
    });

    _socket!.onDisconnect((_) {
      developer.log('❌ Socket desconectado', name: 'SocketService');
    });

    _socket!.onError((error) {
      developer.log('💥 Erro no socket: $error', name: 'SocketService', level: 1000);
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // Entrar em uma conversa
  void joinConversa(int conversaId) {
    _socket?.emit('join_conversa', conversaId);
  }

  // Sair de uma conversa
  void leaveConversa(int conversaId) {
    _socket?.emit('leave_conversa', conversaId);
  }

  // Enviar mensagem
  void sendMensagem(int conversaId, String mensagem) {
    _socket?.emit('nova_mensagem', {
      'conversaId': conversaId,
      'mensagem': mensagem,
    });
  }

  // Marcar mensagens como lidas
  void marcarLidas(int conversaId) {
    _socket?.emit('marcar_lidas', conversaId);
  }

  // Indicar que está digitando
  void typing(int conversaId) {
    _socket?.emit('typing', {'conversaId': conversaId});
  }

  // Parar de digitar
  void stopTyping(int conversaId) {
    _socket?.emit('stop_typing', {'conversaId': conversaId});
  }

  // Listeners
  void onMensagemRecebida(Function(Map<String, dynamic>) callback) {
    _socket?.on('mensagem_recebida', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  void onNovaMensagemNotificacao(Function(Map<String, dynamic>) callback) {
    _socket?.on('nova_mensagem_notificacao', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  void onMensagensLidas(Function(Map<String, dynamic>) callback) {
    _socket?.on('mensagens_lidas', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  void onUserTyping(Function(Map<String, dynamic>) callback) {
    _socket?.on('user_typing', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  void onUserStopTyping(Function(Map<String, dynamic>) callback) {
    _socket?.on('user_stop_typing', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  void onError(Function(dynamic) callback) {
    _socket?.on('error', (error) {
      callback(error);
    });
  }

  // Remover listeners
  void off(String event) {
    _socket?.off(event);
  }

  void offAll() {
    _socket?.clearListeners();
  }
}

