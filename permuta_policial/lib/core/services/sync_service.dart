// /lib/core/services/sync_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../api/api_client.dart';
import 'connectivity_service.dart';

/// Serviço para sincronização inteligente (cache local + fila offline)
class SyncService {
  final AppDatabase _database;
  final ApiClient _apiClient;
  final ConnectivityService _connectivityService;
  
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;
  Timer? _syncTimer;

  SyncService(this._database, this._apiClient, this._connectivityService) {
    _init();
  }

  void _init() {
    // Monitora mudanças de conectividade
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen(
      (isConnected) {
        if (isConnected && !_isSyncing) {
          _syncPendingQueue();
        }
      },
    );

    // Sincroniza periodicamente quando online (a cada 30 segundos)
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_connectivityService.isConnected && !_isSyncing) {
        _syncPendingQueue();
      }
    });
  }

  /// Sincroniza a fila pendente
  Future<void> _syncPendingQueue() async {
    if (_isSyncing || !_connectivityService.isConnected) return;

    _isSyncing = true;
    try {
      final pendingItems = await (_database.select(_database.syncQueue)
            ..where((q) => q.status.equals('PENDING'))
            ..orderBy([(q) => OrderingTerm(expression: q.createdAt)]))
          .get();

      for (final item in pendingItems) {
        try {
          // Marca como sincronizando
          await (_database.update(_database.syncQueue)..where((q) => q.id.equals(item.id)))
              .write(SyncQueueCompanion(status: const Value('SYNCING')));

          // Executa a ação
          switch (item.action) {
            case 'POST':
              await _apiClient.post(
                item.endpoint,
                json.decode(item.data),
              );
              break;
            case 'PUT':
              await _apiClient.put(
                item.endpoint,
                json.decode(item.data),
              );
              break;
            case 'DELETE':
              await _apiClient.delete(item.endpoint);
              break;
          }

          // Marca como completado
          await (_database.update(_database.syncQueue)..where((q) => q.id.equals(item.id)))
              .write(SyncQueueCompanion(
            status: const Value('COMPLETED'),
            syncedAt: Value(DateTime.now()),
          ));
        } catch (e) {
          // Incrementa retry count
          final retryCount = item.retryCount + 1;
          
          // Se exceder 3 tentativas, marca como falha
          if (retryCount >= 3) {
            await (_database.update(_database.syncQueue)..where((q) => q.id.equals(item.id)))
                .write(SyncQueueCompanion(
              status: const Value('FAILED'),
              error: Value(e.toString()),
            ));
          } else {
            // Mantém como PENDING para retry
            await (_database.update(_database.syncQueue)..where((q) => q.id.equals(item.id)))
                .write(SyncQueueCompanion(
              retryCount: Value(retryCount),
              status: const Value('PENDING'),
              error: Value(e.toString()),
            ));
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Adiciona item à fila de sincronização
  Future<void> addToSyncQueue({
    required String action,
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    await _database.into(_database.syncQueue).insert(
      SyncQueueCompanion.insert(
        action: action,
        endpoint: endpoint,
        data: json.encode(data),
        createdAt: DateTime.now(),
      ),
    );

    // Tenta sincronizar imediatamente se online
    if (_connectivityService.isConnected) {
      _syncPendingQueue();
    }
  }

  /// Limpa itens completados ou falhados (mais de 7 dias)
  Future<void> cleanOldSyncItems() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    
    await (_database.delete(_database.syncQueue)
          ..where((q) => 
            (q.status.equals('COMPLETED') | q.status.equals('FAILED')) &
            q.createdAt.isSmallerThanValue(sevenDaysAgo)))
        .go();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }
}

