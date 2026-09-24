// /lib/core/config/app_config.dart

import 'package:flutter/foundation.dart';
import '../utils/platform_utils.dart';

/// Configuração do ambiente da aplicação
enum Environment {
  production,
  development,
}

/// Configuração centralizada da aplicação
class AppConfig {
  // Singleton
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  /// Ambiente atual - detecta baseado no hostname da URL
  static Environment get environment {
    // 1. PRIORIDADE: Tenta detectar via variável de ambiente (build-time)
    // Esta é a forma mais confiável e deve ser usada em builds de produção
    const env = String.fromEnvironment('ENV', defaultValue: '');
    if (env == 'prod') {
      return Environment.production;
    }
    if (env == 'dev') {
      return Environment.development;
    }

    // 2. FALLBACK: Detecta baseado no hostname atual (runtime) - apenas em web
    // Esta detecção é útil quando ENV não foi definido no build
    try {
      final hostname = getHost().toLowerCase();
      
      // Se o hostname contém "dev", usa desenvolvimento
      if (hostname.contains('dev.') || hostname.contains('localhost') || hostname.contains('127.0.0.1')) {
        return Environment.development;
      }
      
      // Se o hostname é o domínio de produção, usa produção
      if (hostname == 'br.permutapolicial.com.br' || hostname == 'www.br.permutapolicial.com.br') {
        return Environment.production;
      }
      
      // Caso contrário, usa produção como padrão (mais seguro)
      return Environment.production;
    } catch (e) {
      // 3. ÚLTIMO FALLBACK: Se não conseguir detectar (ex: não está rodando em web)
      // Em release mode, sempre usa produção. Em debug, usa desenvolvimento.
      if (kReleaseMode) {
        return Environment.production;
      }
      return Environment.development;
    }
  }

  /// URL base da API
  static String get apiBaseUrl {
    switch (environment) {
      case Environment.development:
        return 'https://dev.br.permutapolicial.com.br';
      case Environment.production:
        return 'https://br.permutapolicial.com.br';
    }
  }

  /// URL base do WebSocket
  static String get socketBaseUrl {
    switch (environment) {
      case Environment.development:
        return 'https://dev.br.permutapolicial.com.br';
      case Environment.production:
        return 'https://br.permutapolicial.com.br';
    }
  }

  /// Porta do WebSocket (se necessário)
  static int? get socketPort {
    switch (environment) {
      case Environment.development:
        return null; // Usa a porta padrão do servidor (3001 via proxy)
      case Environment.production:
        return null; // Usa a porta padrão do servidor
    }
  }

  /// Se está em modo de desenvolvimento
  static bool get isDevelopment => environment == Environment.development;

  /// Se está em modo de produção
  static bool get isProduction => environment == Environment.production;

  /// Web Client ID do Google (OAuth) — obrigatório para Google Sign-In nativo no APK.
  /// Passe no build: --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com
  static String? get googleServerClientId {
    const id = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');
    return id.isEmpty ? null : id;
  }

  /// Loga informações sobre o ambiente atual (somente ENV=dev)
  static void logEnvironment() {
    const env = String.fromEnvironment('ENV', defaultValue: '');
    if (env != 'dev') return;
    debugPrint('═══════════════════════════════════════');
    debugPrint('🔧 CONFIGURAÇÃO DO AMBIENTE');
    debugPrint('📍 Ambiente: ${environment.name}');
    debugPrint('📍 API Base URL: $apiBaseUrl');
    debugPrint('📍 Socket Base URL: $socketBaseUrl');
    debugPrint('═══════════════════════════════════════');
  }
}

