// /lib/core/services/socket_service.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../services/storage_service.dart';
import '../config/app_config.dart';

class SocketService {
  io.Socket? _socket;
  final StorageService _storageService;
  final String _baseUrl = AppConfig.socketBaseUrl;

  SocketService(this._storageService);

  bool get isConnected => _socket?.connected ?? false;

  /// Reconecta após retorno do background se havia socket ativo ou desconectado.
  Future<void> reconnectIfNeeded() async {
    final token = await _storageService.getToken();
    if (token == null || token.isEmpty) return;

    if (_socket == null) return;

    if (_socket!.connected) return;

    try {
      _socket!.connect();
    } catch (e) {
      developer.log('⚠️ Falha ao reconectar socket, recriando: $e', name: 'SocketService');
      disconnect();
      try {
        await connect();
      } catch (e2) {
        developer.log('❌ Reconexão socket falhou: $e2', name: 'SocketService', level: 900);
      }
    }
  }

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

  void joinMapaTaticoGroup(int groupId) {
    _socket?.emit('join_mapa_tatico_group', groupId);
  }

  void leaveMapaTaticoGroup(int groupId) {
    _socket?.emit('leave_mapa_tatico_group', groupId);
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

  void onMapaTaticoPointCreated(Function(Map<String, dynamic>) callback) {
    _socket?.on('mapa_tatico_point_created', (data) {
      callback(Map<String, dynamic>.from(data as Map));
    });
  }

  void onMapaTaticoPointUpdated(Function(Map<String, dynamic>) callback) {
    _socket?.on('mapa_tatico_point_updated', (data) {
      callback(Map<String, dynamic>.from(data as Map));
    });
  }

  void onMapaTaticoPointDeleted(Function(Map<String, dynamic>) callback) {
    _socket?.on('mapa_tatico_point_deleted', (data) {
      callback(Map<String, dynamic>.from(data as Map));
    });
  }

  void onMapaTaticoCommentAdded(Function(Map<String, dynamic>) callback) {
    _socket?.on('mapa_tatico_comment_added', (data) {
      callback(Map<String, dynamic>.from(data as Map));
    });
  }

  void onMapaTaticoMemberJoined(Function(Map<String, dynamic>) callback) {
    _socket?.on('mapa_tatico_member_joined', (data) {
      callback(Map<String, dynamic>.from(data as Map));
    });
  }

  void onMapaTaticoLocationUpdated(Function(Map<String, dynamic>) callback) {
    _socket?.on('mapa_tatico_location_updated', (data) {
      callback(Map<String, dynamic>.from(data as Map));
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

