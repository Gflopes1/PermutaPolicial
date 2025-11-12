// /lib/core/api/api_client.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import 'api_exception.dart';

class ApiClient {
  final StorageService _storageService;

  final String _baseUrl = 'https://br.permutapolicial.com.br';
  
  // Configurações de timeout e retry
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 1);
  
  String get baseUrl => _baseUrl;
  
  ApiClient(this._storageService);

  /// Obtém os headers da requisição
  Future<Map<String, String>> _getHeaders({String? token}) async {
    final finalToken = token ?? await _storageService.getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (finalToken != null) 'Authorization': 'Bearer $finalToken',
    };
  }

  /// Executa uma requisição com retry automático
  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() request, {
    int retries = _maxRetries,
  }) async {
    int attempts = 0;
    
    while (attempts <= retries) {
      try {
        final response = await request().timeout(_defaultTimeout);
        
        // Se a resposta foi bem-sucedida ou é um erro que não deve ser retentado, retorna
        if (response.statusCode < 500 || attempts >= retries) {
          return response;
        }
        
        // Para erros 5xx, tenta novamente
        if (response.statusCode >= 500 && attempts < retries) {
          await Future.delayed(_retryDelay * (attempts + 1));
          attempts++;
          continue;
        }
        
        return response;
      } on TimeoutException {
        if (attempts >= retries) {
          throw ApiException(
            message: 'Tempo de conexão esgotado. Verifique sua internet e tente novamente.',
            errorCode: ApiErrorCode.timeoutError,
            originalError: 'Timeout após ${_defaultTimeout.inSeconds}s',
          );
        }
        await Future.delayed(_retryDelay * (attempts + 1));
        attempts++;
      } on SocketException catch (e) {
        if (attempts >= retries) {
          throw ApiException(
            message: 'Sem conexão com a internet. Verifique sua rede e tente novamente.',
            errorCode: ApiErrorCode.connectionError,
            originalError: e.toString(),
          );
        }
        await Future.delayed(_retryDelay * (attempts + 1));
        attempts++;
      } catch (e) {
        // Se for ApiException, re-lança imediatamente
        if (e is ApiException) rethrow;
        
        // Para outros erros, tenta novamente se ainda houver tentativas
        if (attempts >= retries) {
          throw ApiException(
            message: 'Erro de conexão: Verifique sua rede e tente novamente.',
            errorCode: ApiErrorCode.connectionError,
            originalError: e.toString(),
          );
        }
        await Future.delayed(_retryDelay * (attempts + 1));
        attempts++;
      }
    }
    
    // Nunca deve chegar aqui, mas por segurança
    throw ApiException(
      message: 'Erro ao conectar com o servidor. Tente novamente mais tarde.',
      errorCode: ApiErrorCode.connectionError,
    );
  }

  /// Método GET
  Future<dynamic> get(String endpoint, {String? token}) async {
    debugPrint('GET: $_baseUrl$endpoint');
    
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders(token: token);
      final response = await _executeWithRetry(
        () async => http.get(uri, headers: headers),
      );
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Erro inesperado ao fazer requisição.',
        errorCode: ApiErrorCode.unknownError,
        originalError: e.toString(),
      );
    }
  }

  /// Método POST
  Future<dynamic> post(String endpoint, Map<String, dynamic> data, {String? token}) async {
    debugPrint('POST: $_baseUrl$endpoint');
    
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final body = json.encode(data);
      final headers = await _getHeaders(token: token);
      final response = await _executeWithRetry(
        () async => http.post(uri, headers: headers, body: body),
      );
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Erro inesperado ao fazer requisição.',
        errorCode: ApiErrorCode.unknownError,
        originalError: e.toString(),
      );
    }
  }

  /// Método PUT
  Future<dynamic> put(String endpoint, Map<String, dynamic> data, {String? token}) async {
    debugPrint('PUT: $_baseUrl$endpoint');
    
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final body = json.encode(data);
      final headers = await _getHeaders(token: token);
      final response = await _executeWithRetry(
        () async => http.put(uri, headers: headers, body: body),
      );
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Erro inesperado ao fazer requisição.',
        errorCode: ApiErrorCode.unknownError,
        originalError: e.toString(),
      );
    }
  }

  /// Trata a resposta HTTP e converte erros em ApiException
  dynamic _handleResponse(http.Response response) {
    try {
      // Tenta decodificar o JSON
      final jsonBody = json.decode(utf8.decode(response.bodyBytes));

      // Resposta bem-sucedida
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Retorna 'data' se existir, senão retorna o body completo
        return jsonBody['data'] ?? jsonBody;
      }

      // Trata erros da API
      final errorData = jsonBody['error'] ?? jsonBody;
      final errorCode = errorData['code'] as String?;
      final errorMessage = errorData['message'] as String? ?? 
                          jsonBody['message'] as String? ?? 
                          'Ocorreu um erro inesperado no servidor.';
      final errorDetails = errorData['details'] as Map<String, dynamic>?;

      throw ApiException.fromErrorCode(
        errorCode,
        errorMessage,
        response.statusCode,
        details: errorDetails,
      );
    } on FormatException catch (e) {
      // Erro ao decodificar JSON
      throw ApiException(
        message: 'Resposta inválida do servidor.',
        statusCode: response.statusCode,
        errorCode: ApiErrorCode.unknownError,
        originalError: e.toString(),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      // Erro genérico
      throw ApiException(
        message: 'Erro ao processar resposta do servidor.',
        statusCode: response.statusCode,
        errorCode: ApiErrorCode.unknownError,
        originalError: e.toString(),
      );
    }
  }
}