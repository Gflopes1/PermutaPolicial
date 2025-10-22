// /lib/core/api/api_client.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import 'api_exception.dart';

class ApiClient {
  final StorageService _storageService;

  final String _baseUrl = 'https://br.permutapolicial.com.br';
  
  String get baseUrl => _baseUrl;
  
  ApiClient(this._storageService);

  // CORREÇÃO APLICADA AQUI
  Future<Map<String, String>> _getHeaders({String? token}) async {
    final finalToken = token ?? await _storageService.getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (finalToken != null) 'Authorization': 'Bearer $finalToken',
    };
  }

  // CORREÇÃO APLICADA AQUI
  Future<dynamic> get(String endpoint, {String? token}) async {
    debugPrint('GET: $_baseUrl$endpoint');
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http.get(uri, headers: await _getHeaders(token: token));
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Erro de conexão: Verifique sua rede e tente novamente.');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data, {String? token}) async {
     try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http.post(uri, headers: await _getHeaders(token: token), body: json.encode(data));
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Erro de conexão: Verifique sua rede e tente novamente.');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data, {String? token}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http.put(uri, headers: await _getHeaders(token: token), body: json.encode(data));
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Erro de conexão: Verifique sua rede e tente novamente.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final jsonBody = json.decode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody['data'];
    } else {
      throw ApiException(
        message: jsonBody['message'] ?? 'Ocorreu um erro inesperado no servidor.',
        statusCode: response.statusCode,
      );
    }
  }
}