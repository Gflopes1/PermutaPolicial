// /lib/core/services/connectivity_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Serviço para monitorar conectividade (mobile e web)
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _connectivityController;
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isConnected = true; // Assume conectado por padrão

  ConnectivityService() {
    _connectivityController = StreamController<bool>.broadcast();
    _init();
  }

  /// Inicializa o monitoramento de conectividade
  Future<void> _init() async {
    // Verifica o status inicial
    await checkConnectivity();

    // Monitora mudanças na conectividade
    _subscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        _updateConnectionStatus(result);
      },
    );
  }

  /// Verifica o status atual da conectividade
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Erro ao verificar conectividade: $e');
      // Em caso de erro, assume conectado (melhor UX)
      return true;
    }
  }

  /// Atualiza o status de conexão baseado no resultado
  bool _updateConnectionStatus(ConnectivityResult result) {
    // Em web, sempre considera conectado (navegador gerencia isso)
    if (kIsWeb) {
      _isConnected = true;
      _connectivityController?.add(true);
      return true;
    }

    // Em mobile, verifica se há conexão disponível
    final isConnected = result != ConnectivityResult.none;
    
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectivityController?.add(isConnected);
    }
    
    return isConnected;
  }

  /// Stream de mudanças na conectividade
  Stream<bool> get onConnectivityChanged => 
    _connectivityController?.stream ?? const Stream<bool>.empty();

  /// Status atual da conexão
  bool get isConnected => _isConnected;

  /// Dispose do serviço
  void dispose() {
    _subscription?.cancel();
    _connectivityController?.close();
  }
}

