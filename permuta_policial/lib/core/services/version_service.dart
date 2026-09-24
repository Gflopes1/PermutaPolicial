// /lib/core/services/version_service.dart

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/storage_service.dart';

/// Serviço para gerenciar versionamento e cache busting
/// Garante que usuários sempre recebam a versão mais recente após deploy
class VersionService {
  static const String _versionKey = 'app_version';
  static const String _buildNumberKey = 'app_build_number';
  static const String _cacheVersionKey = 'cache_version';

  VersionService(StorageService storageService);

  /// Obtém a versão atual do app
  Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint('Erro ao obter versão: $e');
      return '1.0.0';
    }
  }

  /// Obtém o build number atual do app
  Future<String> getCurrentBuildNumber() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.buildNumber;
    } catch (e) {
      debugPrint('Erro ao obter build number: $e');
      return '1';
    }
  }

  /// Obtém a versão armazenada (última versão conhecida)
  Future<String?> getStoredVersion() async {
    // Usa FlutterSecureStorage diretamente para armazenar versão
    const storage = FlutterSecureStorage();
    return await storage.read(key: _versionKey);
  }

  /// Obtém o build number armazenado
  Future<String?> getStoredBuildNumber() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: _buildNumberKey);
  }

  /// Verifica se houve atualização do app
  Future<bool> hasAppUpdated() async {
    final currentVersion = await getCurrentVersion();
    final currentBuild = await getCurrentBuildNumber();
    final storedVersion = await getStoredVersion();
    final storedBuild = await getStoredBuildNumber();

    // Se não há versão armazenada, é a primeira execução
    if (storedVersion == null || storedBuild == null) {
      await _saveCurrentVersion();
      return false;
    }

    // Verifica se a versão ou build mudou
    final hasUpdated = currentVersion != storedVersion || currentBuild != storedBuild;
    
    if (hasUpdated) {
      await _saveCurrentVersion();
      // Limpa cache de versão para forçar refresh
      await _incrementCacheVersion();
    }

    return hasUpdated;
  }

  /// Salva a versão atual
  Future<void> _saveCurrentVersion() async {
    final version = await getCurrentVersion();
    final build = await getCurrentBuildNumber();
    const storage = FlutterSecureStorage();
    await storage.write(key: _versionKey, value: version);
    await storage.write(key: _buildNumberKey, value: build);
  }

  /// Obtém a versão do cache (usado para cache busting)
  Future<String> getCacheVersion() async {
    const storage = FlutterSecureStorage();
    final cacheVersion = await storage.read(key: _cacheVersionKey);
    if (cacheVersion == null) {
      // Primeira execução: usa timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      await storage.write(key: _cacheVersionKey, value: timestamp);
      return timestamp;
    }
    return cacheVersion;
  }

  /// Incrementa a versão do cache (força refresh)
  Future<void> _incrementCacheVersion() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    const storage = FlutterSecureStorage();
    await storage.write(key: _cacheVersionKey, value: timestamp);
  }

  /// Força atualização do cache (pode ser chamado manualmente)
  Future<void> forceCacheUpdate() async {
    await _incrementCacheVersion();
  }

  /// Gera um parâmetro de query para cache busting
  /// Exemplo: ?v=1234567890
  Future<String> getCacheBustingParam() async {
    final cacheVersion = await getCacheVersion();
    return 'v=$cacheVersion';
  }

  /// Adiciona cache busting a uma URL
  Future<String> addCacheBustingToUrl(String url) async {
    if (url.isEmpty) return url;
    
    final cacheParam = await getCacheBustingParam();
    final uri = Uri.parse(url);
    
    // Se já tem query parameters, adiciona o cache busting
    if (uri.hasQuery) {
      final queryParams = Map<String, String>.from(uri.queryParameters);
      queryParams['v'] = await getCacheVersion();
      return uri.replace(queryParameters: queryParams).toString();
    } else {
      // Se não tem query parameters, adiciona
      return '$url?$cacheParam';
    }
  }
}

