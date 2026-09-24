// /lib/core/api/api_client.dart

import 'dart:convert';
import 'dart:async'; // Para TimeoutException
// Removido import de dart:io - não é necessário mais pois não usamos SocketException/HttpException diretamente
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'http_client_factory.dart'; // Factory para criar cliente HTTP
import '../services/storage_service.dart';
import 'api_exception.dart';
import '../config/app_config.dart';
import '../../../shared/widgets/premium_modal.dart';
import 'package:go_router/go_router.dart';
import '../config/app_router.dart';
import '../utils/app_logger.dart';

class ApiClient {
  final StorageService _storageService;
  final http.Client _httpClient;

  final String _baseUrl = AppConfig.apiBaseUrl;
  static const Duration _timeoutDuration = Duration(seconds: 30);

  static void _devLog(String message) {
    if (AppLogger.isDevLoggingEnabled) {
      debugPrint(message);
    }
  }
  
  // GlobalKey para acesso ao Navigator global
  // Será configurado no main.dart via setNavigatorKey()
  static GlobalKey<NavigatorState>? navigatorKey;
  
  // ✅ Previne múltiplas chamadas simultâneas de tratamento de token expirado
  static bool _isHandlingTokenExpired = false;

  /// Callback para sincronizar logout com AuthProvider.
  static Future<void> Function()? onSessionExpired;
  
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }
  
  String get baseUrl => _baseUrl;
  
  ApiClient(this._storageService) : _httpClient = createHttpClient(_timeoutDuration);

  Future<Map<String, String>> _getHeaders({String? token, bool requireAuth = true}) async {
    String? finalToken;
    if (token != null) {
      finalToken = token.isEmpty ? null : token;
    } else if (requireAuth) {
      finalToken = await _storageService.getToken();
    }

    // Log de token apenas em ambiente de desenvolvimento (ENV=dev)
    if (finalToken != null) {
      _devLog('🔑 ApiClient: requisição autenticada');
    } else {
      _devLog('ℹ️ ApiClient: requisição sem token (endpoint público ou primeiro acesso)');
    }

    return {
      'Content-Type': 'application/json; charset=UTF-8', // CORRIGIDO: UTF-8
      if (finalToken != null) 'Authorization': 'Bearer $finalToken',
    };
  }

  static bool _isPublicReferralPath(String path) {
    return RegExp(r'^/r/[A-Za-z0-9]+/?$').hasMatch(path) ||
        path == '/auth/register' ||
        path == '/auth/confirm-email' ||
        path == '/landing';
  }

  Future<dynamic> get(String endpoint, {String? token, bool requireAuth = true}) async {
    _devLog('GET: $_baseUrl$endpoint');
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await _httpClient
          .get(uri, headers: await _getHeaders(token: token, requireAuth: requireAuth))
          .timeout(_timeoutDuration);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;

      // Trata erros de conexão (SocketException no mobile, ClientException na web)
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        throw ApiException(
          message: 'Sem conexão com a internet. Verifique sua rede e tente novamente.',
          code: 'NO_CONNECTION',
        );
      }
      
      // Trata erros HTTP
      if (e.toString().contains('HttpException')) {
        throw ApiException(
          message: 'Erro de comunicação com o servidor.',
          code: 'HTTP_ERROR',
        );
      }
      
      if (e is FormatException) {
        throw ApiException(
          message: 'Resposta inválida do servidor. Tente novamente.',
          code: 'INVALID_RESPONSE',
        );
      }
      
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        throw ApiException(
          message: 'A requisição demorou muito. Verifique sua conexão e tente novamente.',
          code: 'TIMEOUT',
        );
      }
      // No navegador, erros de rede (sem conexão) cairão aqui como ClientException
      throw ApiException(
        message: 'Erro de conexão: Verifique sua rede e tente novamente.',
        code: 'CONNECTION_ERROR',
      );
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data, {String? token, bool requireAuth = true}) async {
    _devLog('POST: $_baseUrl$endpoint');
    _devLog('POST Body: ${json.encode(data)}');
    
    // Log da origem atual (para debug de CORS)
    if (kIsWeb && AppLogger.isDevLoggingEnabled) {
      try {
        final origin = Uri.base.origin;
        _devLog('📍 Origem da requisição: $origin');
      } catch (e) {
        _devLog('⚠️ Não foi possível obter a origem: $e');
      }
    }
    
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders(token: token, requireAuth: requireAuth);
      _devLog('📍 Headers: ${headers.keys.join(", ")}');

      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: json.encode(data),
          )
          .timeout(_timeoutDuration);
      _devLog('POST Response Status: ${response.statusCode}');
      if (AppLogger.isDevLoggingEnabled) {
        if (response.body.length < 10000) {
          _devLog('POST Response Body: ${response.body}');
        } else {
          _devLog('POST Response Body: (muito grande, ${response.body.length} caracteres)');
        }
      }
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw ApiException(
          message: 'Sem conexão com a internet. Verifique sua rede e tente novamente.',
          code: 'NO_CONNECTION',
        );
      }
      
      if (e.toString().contains('HttpException')) {
        throw ApiException(
          message: 'Erro de comunicação com o servidor.',
          code: 'HTTP_ERROR',
        );
      }
      
      if (e is FormatException) {
        _devLog('FormatException em POST: $e');
        throw ApiException(
          message: 'Resposta inválida do servidor. Tente novamente.',
          code: 'INVALID_RESPONSE',
        );
      }
      
      _devLog('Erro não tratado em POST: $e');
      _devLog('Tipo do erro: ${e.runtimeType}');
      
      // Trata especificamente ClientException (erro de rede/CORS no navegador)
      if (e.toString().contains('ClientException') || 
          e.toString().contains('Failed to fetch') ||
          e.toString().contains('NetworkError')) {
        _devLog('🚨 Erro de rede/CORS detectado. Verifique:');
        _devLog('   1. Se o servidor está rodando em $_baseUrl');
        _devLog('   2. Se a origem está permitida no CORS do backend');
        _devLog('   3. Se não há problemas de rede/firewall');
        throw ApiException(
          message: 'Erro de conexão com o servidor. Verifique se o servidor está acessível e se não há problemas de CORS.',
          code: 'CONNECTION_ERROR',
        );
      }
      
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        throw ApiException(
          message: 'A requisição demorou muito. Verifique sua conexão e tente novamente.',
          code: 'TIMEOUT',
        );
      }
      throw ApiException(
        message: 'Erro de conexão: Verifique sua rede e tente novamente.',
        code: 'CONNECTION_ERROR',
      );
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data, {String? token}) async {
    _devLog('PUT: $_baseUrl$endpoint'); // ADICIONADO: Log para debug
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await _httpClient
          .put(
            uri,
            headers: await _getHeaders(token: token),
            body: json.encode(data),
          )
          .timeout(_timeoutDuration);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw ApiException(
          message: 'Sem conexão com a internet. Verifique sua rede e tente novamente.',
          code: 'NO_CONNECTION',
        );
      }
      
      if (e.toString().contains('HttpException')) {
        throw ApiException(
          message: 'Erro de comunicação com o servidor.',
          code: 'HTTP_ERROR',
        );
      }
      
      if (e is FormatException) {
        throw ApiException(
          message: 'Resposta inválida do servidor. Tente novamente.',
          code: 'INVALID_RESPONSE',
        );
      }
      
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        throw ApiException(
          message: 'A requisição demorou muito. Verifique sua conexão e tente novamente.',
          code: 'TIMEOUT',
        );
      }
      throw ApiException(
        message: 'Erro de conexão: Verifique sua rede e tente novamente.',
        code: 'CONNECTION_ERROR',
      );
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data, {String? token}) async {
    _devLog('PATCH: $_baseUrl$endpoint');
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await _httpClient
          .patch(
            uri,
            headers: await _getHeaders(token: token),
            body: json.encode(data),
          )
          .timeout(_timeoutDuration);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw ApiException(
          message: 'Sem conexão com a internet. Verifique sua rede e tente novamente.',
          code: 'NO_CONNECTION',
        );
      }
      if (e.toString().contains('HttpException')) {
        throw ApiException(
          message: 'Erro de comunicação com o servidor.',
          code: 'HTTP_ERROR',
        );
      }
      if (e is FormatException) {
        throw ApiException(
          message: 'Resposta inválida do servidor. Tente novamente.',
          code: 'INVALID_RESPONSE',
        );
      }
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        throw ApiException(
          message: 'A requisição demorou muito. Verifique sua conexão e tente novamente.',
          code: 'TIMEOUT',
        );
      }
      throw ApiException(
        message: 'Erro de conexão: Verifique sua rede e tente novamente.',
        code: 'CONNECTION_ERROR',
      );
    }
  }

  dynamic _handleResponse(http.Response response) {
    _devLog('Response Status Code: ${response.statusCode}');
    
    // Verifica se a resposta é HTML (geralmente indica erro do servidor)
    final contentType = response.headers['content-type'] ?? '';
    final isHtml = contentType.contains('text/html') || 
                   response.body.trim().startsWith('<!DOCTYPE') ||
                   response.body.trim().startsWith('<html');
    
    if (isHtml) {
      _devLog('⚠️ Resposta HTML recebida (provavelmente página de erro do servidor)');
      _devLog('   Content-Type: $contentType');
      // Não imprime o body HTML completo para evitar poluir o console
      throw ApiException(
        message: 'O servidor retornou uma resposta inválida. Tente novamente.',
        statusCode: response.statusCode,
        code: 'HTML_RESPONSE',
      );
    }
    
    // Só imprime o body se não for muito grande e for JSON
    if (response.body.length < 10000) {
      _devLog('Response Body: ${response.body}');
    } else {
      _devLog('Response Body: (muito grande, ${response.body.length} caracteres)');
    }
    
    // ✅ Log específico para erro 401
    if (response.statusCode == 401) {
      _devLog('🚨 ERRO 401 DETECTADO! Não autorizado.');
      _devLog('   Headers da resposta: ${response.headers}');
    }
    
    try {
      final jsonBody = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Se a resposta é uma List, retorna diretamente
        if (jsonBody is List) {
          return jsonBody;
        }
        
        // Se a resposta tem estrutura de paginação (data, total, page, perPage), retorna o objeto completo
        // Caso contrário, retorna apenas 'data' se existir, senão retorna o corpo inteiro
        if (jsonBody is Map<String, dynamic> && 
            jsonBody.containsKey('data') && 
            (jsonBody.containsKey('total') || jsonBody.containsKey('page') || jsonBody.containsKey('perPage'))) {
          // Resposta paginada - retorna objeto completo
          return jsonBody;
        }
        // Resposta simples - retorna apenas 'data' se existir
        if (jsonBody is Map<String, dynamic>) {
        return jsonBody['data'] ?? jsonBody;
        }
        // Se não for Map nem List, retorna como está
        return jsonBody;
      } else {
        // Extrai informações do erro da resposta
        // Tenta ler 'message' primeiro, depois 'error' (para compatibilidade)
        final errorMessage = jsonBody['message'] ?? 
                            jsonBody['error'] ?? 
                            'Ocorreu um erro inesperado no servidor.';
        final errorCode = jsonBody['code'];
        final errorDetails = jsonBody['details'];

        // ✅ Log específico para erro 401
        if (response.statusCode == 401) {
          _devLog('🚨 ERRO 401: $errorMessage');
          _devLog('   Código: $errorCode');
          
          // ✅ CORREÇÃO: Se o token expirou ou é inválido, faz logout automático e redireciona para login
          if (errorCode == 'TOKEN_EXPIRED' || errorCode == 'INVALID_TOKEN' || errorMessage.toLowerCase().contains('token')) {
            _devLog('🔐 Token expirado ou inválido. Fazendo logout automático...');
            _handleTokenExpired();
          }
        }

        // ✅ Intercepta erros 403 com código LIMIT_REACHED ou mensagem de Premium
        if (response.statusCode == 403) {
          final isLimitReached = errorCode == 'LIMIT_REACHED' ||
              errorMessage.toLowerCase().contains('premium') ||
              errorMessage.toLowerCase().contains('assinatura') ||
              errorMessage.toLowerCase().contains('limite') ||
              errorMessage.toLowerCase().contains('recurso disponível apenas para usuários premium');
          
          if (isLimitReached) {
            _devLog('🚨 ERRO 403: Limite atingido ou recurso Premium. Abrindo modal...');
            ApiClient.showPremiumModal();
          }
        }

        throw ApiException(
          message: errorMessage,
          statusCode: response.statusCode,
          code: errorCode,
          details: errorDetails != null ? Map<String, dynamic>.from(errorDetails) : null,
        );
      }
    } on FormatException catch (e) {
      _devLog('Erro ao decodificar JSON: $e');
      // Verifica novamente se é HTML para não imprimir o body completo
      final contentType = response.headers['content-type'] ?? '';
      final isHtmlResponse = contentType.contains('text/html') || 
                            response.body.trim().startsWith('<!DOCTYPE') ||
                            response.body.trim().startsWith('<html');
      
      if (isHtmlResponse) {
        _devLog('Resposta HTML detectada (não é JSON válido)');
      } else {
        // Só imprime o body se não for muito grande
        if (response.body.length < 500) {
          _devLog('Response body que causou erro: ${response.body}');
        } else {
          _devLog('Response body que causou erro: (muito grande, ${response.body.length} caracteres)');
        }
      }
      // Se não conseguir decodificar o JSON, lança uma exceção genérica
      throw ApiException(
        message: 'Resposta inválida do servidor. Tente novamente.',
        statusCode: response.statusCode,
        code: 'INVALID_RESPONSE',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      _devLog('Erro não tratado em _handleResponse: $e');
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint, {String? token}) async {
    _devLog('DELETE: $_baseUrl$endpoint'); // ADICIONADO: Log para debug
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await _httpClient
          .delete(
            uri,
            headers: await _getHeaders(token: token),
          )
          .timeout(_timeoutDuration);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw ApiException(
          message: 'Sem conexão com a internet. Verifique sua rede e tente novamente.',
          code: 'NO_CONNECTION',
        );
      }
      
      if (e.toString().contains('HttpException')) {
        throw ApiException(
          message: 'Erro de comunicação com o servidor.',
          code: 'HTTP_ERROR',
        );
      }
      
      if (e is FormatException) {
        throw ApiException(
          message: 'Resposta inválida do servidor. Tente novamente.',
          code: 'INVALID_RESPONSE',
        );
      }
      
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        throw ApiException(
          message: 'A requisição demorou muito. Verifique sua conexão e tente novamente.',
          code: 'TIMEOUT',
        );
      }
      throw ApiException(
        message: 'Erro de conexão: Verifique sua rede e tente novamente.',
        code: 'CONNECTION_ERROR',
      );
    }
  }

  Future<dynamic> deleteWithBody(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    _devLog('DELETE(body): $_baseUrl$endpoint');
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders(token: token);
      headers['Content-Type'] = 'application/json';
      final response = await _httpClient
          .delete(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeoutDuration);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Erro de conexão: Verifique sua rede e tente novamente.',
        code: 'CONNECTION_ERROR',
      );
    }
  }

  Future<dynamic> postMultipart(String endpoint, Map<String, dynamic> data, List<http.MultipartFile> files, {String? token}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);
      
      final headers = await _getHeaders(token: token);
      headers.remove('Content-Type'); // Remove Content-Type para multipart
      request.headers.addAll(headers);
      
      // Adiciona campos de texto
      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });
      
      // Adiciona arquivos
      request.files.addAll(files);
      
      final streamedResponse = await request.send().timeout(_timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw ApiException(
          message: 'Sem conexão com a internet. Verifique sua rede e tente novamente.',
          code: 'NO_CONNECTION',
        );
      }
      
      throw ApiException(
        message: 'Erro ao fazer upload: ${e.toString()}',
        code: 'UPLOAD_ERROR',
      );
    }
  }

  Future<dynamic> putMultipart(String endpoint, Map<String, dynamic> data, List<http.MultipartFile> files, {String? token}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest('PUT', uri);
      
      final headers = await _getHeaders(token: token);
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      
      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });
      
      request.files.addAll(files);
      
      final streamedResponse = await request.send().timeout(_timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw ApiException(
          message: 'Sem conexão com a internet. Verifique sua rede e tente novamente.',
          code: 'NO_CONNECTION',
        );
      }
      
      throw ApiException(
        message: 'Erro ao fazer upload: ${e.toString()}',
        code: 'UPLOAD_ERROR',
      );
    }
  }

  /// Exibe o modal Premium quando um limite é atingido ou recurso Premium é necessário
  static void showPremiumModal() {
    if (navigatorKey?.currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey?.currentContext != null) {
          showDialog(
            context: navigatorKey!.currentContext!,
            barrierDismissible: true,
            builder: (context) => const PremiumModal(),
          );
        }
      });
    } else {
      _devLog('⚠️ NavigatorKey não configurado. Não é possível exibir modal Premium.');
    }
  }

  /// ✅ CORREÇÃO: Trata token expirado - limpa storage e redireciona para login
  void _handleTokenExpired() {
    _devLog('🔐 ApiClient: Tratando token expirado...');
    
    // Previne múltiplas chamadas simultâneas
    if (_isHandlingTokenExpired) {
      _devLog('⚠️ Já está tratando token expirado, ignorando chamada duplicada');
      return;
    }
    _isHandlingTokenExpired = true;
    
    Future<void>(() async {
      try {
        await onSessionExpired?.call();
      } catch (e) {
        _devLog('⚠️ Erro ao sincronizar sessão expirada: $e');
      }
      try {
        await _storageService.deleteToken();
        _devLog('✅ Token removido do storage');
      } catch (e) {
        _devLog('⚠️ Erro ao remover token: $e');
      } finally {
        _isHandlingTokenExpired = false;
      }
    });
    
    // Redireciona para tela de login após um pequeno delay
    // Usa WidgetsBinding para garantir que está no contexto correto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey?.currentContext;
      if (context != null) {
        try {
          final path = GoRouterState.of(context).uri.path;
          if (_isPublicReferralPath(path)) {
            _devLog('Token expirado em rota pública ($path) — sessão limpa, sem redirect');
            _isHandlingTokenExpired = false;
            return;
          }
        } catch (_) {}

        _devLog('🔄 Redirecionando para tela de login...');
        context.go('${AppRoutes.auth}?error=${Uri.encodeComponent('Sua sessão expirou. Por favor, faça login novamente.')}');
        _isHandlingTokenExpired = false;
      } else {
        _devLog('⚠️ Context não disponível para redirecionar para login');
        Future.delayed(const Duration(milliseconds: 500), () {
          final retryContext = navigatorKey?.currentContext;
          if (retryContext != null) {
            try {
              final path = GoRouterState.of(retryContext).uri.path;
              if (_isPublicReferralPath(path)) {
                _isHandlingTokenExpired = false;
                return;
              }
            } catch (_) {}
            retryContext.go('${AppRoutes.auth}?error=${Uri.encodeComponent('Sua sessão expirou. Por favor, faça login novamente.')}');
          }
          _isHandlingTokenExpired = false;
        });
      }
    });
  }

  void dispose() {
    _httpClient.close();
  }
}