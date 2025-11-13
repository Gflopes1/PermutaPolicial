// /lib/core/api/api_client.dart

import 'dart:convert';
import 'dart:io'; // Necessário para o IOClient no mobile
import 'package:flutter/foundation.dart'; // Necessário para o kIsWeb
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as io_client; // Para mobile
import 'package:http/browser_client.dart' as browser_client; // Para web
import '../services/storage_service.dart';
import 'api_exception.dart';

class ApiClient {
  final StorageService _storageService;
  final http.Client _httpClient;

  final String _baseUrl = 'https://br.permutapolicial.com.br';
  static const Duration _timeoutDuration = Duration(seconds: 30);
  
  String get baseUrl => _baseUrl;
  
  ApiClient(this._storageService) : _httpClient = _createHttpClient();

  /// Cria um cliente HTTP com base na plataforma (Web ou Mobile)
  static http.Client _createHttpClient() {
    if (kIsWeb) {
      // Usa BrowserClient para a Web
      return browser_client.BrowserClient();
    } else {
      // Usa IOClient para Mobile (permite configurar o HttpClient do dart:io)
      final httpClient = HttpClient();
      httpClient.connectionTimeout = _timeoutDuration;
      return io_client.IOClient(httpClient);
    }
  }

  Future<Map<String, String>> _getHeaders({String? token}) async {
    final finalToken = token ?? await _storageService.getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-O',
      if (finalToken != null) 'Authorization': 'Bearer $finalToken',
    };
  }

  Future<dynamic> get(String endpoint, {String? token}) async {
    debugPrint('GET: $_baseUrl$endpoint');
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await _httpClient
          .get(uri, headers: await _getHeaders(token: token))
          .timeout(_timeoutDuration);
      return _handleResponse(response);
    } on SocketException {
      // Este catch só será ativado em plataformas mobile
      throw ApiException(
        message: 'Sem conexão com a internet. Verifique sua rede e tente novamente.',
        code: 'NO_CONNECTION',
      );
    } on HttpException catch (e) {
      // Este catch só será ativado em plataformas mobile
      throw ApiException(
        message: 'Erro de comunicação com o servidor: ${e.message}',
        code: 'HTTP_ERROR',
      );
    } on FormatException {
      throw ApiException(
        message: 'Resposta inválida do servidor. Tente novamente.',
        code: 'INVALID_RESPONSE',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
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

  Future<dynamic> post(String endpoint, Map<String, dynamic> data, {String? token}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await _httpClient
          .post(
            uri,
            headers: await _getHeaders(token: token),
            body: json.encode(data),
          )
          .timeout(_timeoutDuration);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Sem conexão com a internet. Verifique sua rede e tente novamente.',
        code: 'NO_CONNECTION',
      );
    } on HttpException catch (e) {
      throw ApiException(
        message: 'Erro de comunicação com o servidor: ${e.message}',
        code: 'HTTP_ERROR',
      );
    } on FormatException {
      throw ApiException(
        message: 'Resposta inválida do servidor. Tente novamente.',
        code: 'INVALID_RESPONSE',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
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
    } on SocketException {
      throw ApiException(
        message: 'Sem conexão com a internet. Verifique sua rede e tente novamente.',
        code: 'NO_CONNECTION',
      );
    } on HttpException catch (e) {
      throw ApiException(
        message: 'Erro de comunicação com o servidor: ${e.message}',
        code: 'HTTP_ERROR',
      );
    } on FormatException {
      throw ApiException(
        message: 'Resposta inválida do servidor. Tente novamente.',
        code: 'INVALID_RESPONSE',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
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
    try {
      final jsonBody = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonBody['data'] ?? jsonBody;
      } else {
        // Extrai informações do erro da resposta
        final errorMessage = jsonBody['message'] ?? 
            'Ocorreu um erro inesperado no servidor.';
        final errorCode = jsonBody['code'];
        final errorDetails = jsonBody['details'];

        throw ApiException(
          message: errorMessage,
          statusCode: response.statusCode,
          code: errorCode,
          details: errorDetails != null ? Map<String, dynamic>.from(errorDetails) : null,
        );
      }
    } on FormatException {
      // Se não conseguir decodificar o JSON, lança uma exceção genérica
      throw ApiException(
        message: 'Resposta inválida do servidor. Tente novamente.',
        statusCode: response.statusCode,
        code: 'INVALID_RESPONSE',
      );
    }
  }

  Future<dynamic> delete(String endpoint, {String? token}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await _httpClient
          .delete(
            uri,
            headers: await _getHeaders(token: token),
          )
          .timeout(_timeoutDuration);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Sem conexão com a internet. Verifique sua rede e tente novamente.',
        code: 'NO_CONNECTION',
      );
    } on HttpException catch (e) {
      throw ApiException(
        message: 'Erro de comunicação com o servidor: ${e.message}',
        code: 'HTTP_ERROR',
      );
    } on FormatException {
      throw ApiException(
        message: 'Resposta inválida do servidor. Tente novamente.',
        code: 'INVALID_RESPONSE',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
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
    } on SocketException {
      throw ApiException(
        message: 'Sem conexão com a internet. Verifique sua rede e tente novamente.',
        code: 'NO_CONNECTION',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
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
    } on SocketException {
      throw ApiException(
        message: 'Sem conexão com a internet. Verifique sua rede e tente novamente.',
        code: 'NO_CONNECTION',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Erro ao fazer upload: ${e.toString()}',
        code: 'UPLOAD_ERROR',
      );
    }
  }

  void dispose() {
    _httpClient.close();
  }
}