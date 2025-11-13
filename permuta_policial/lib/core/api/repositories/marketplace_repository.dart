// /lib/core/api/repositories/marketplace_repository.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../api_client.dart';
import '../../models/marketplace_item.dart';

class MarketplaceRepository {
  final ApiClient _apiClient;

  MarketplaceRepository(this._apiClient);

  String get _baseUrl => _apiClient.baseUrl;

  Future<List<MarketplaceItem>> getAll({String? tipo, String? search, int page = 1, int limit = 20}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (tipo != null && tipo.isNotEmpty) queryParams['tipo'] = tipo;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse('$_baseUrl/api/marketplace').replace(queryParameters: queryParams);
    final response = await _apiClient.get(uri.toString().replaceFirst(_baseUrl, ''));
    
    if (response is List) {
      return (response as List<Map<String, dynamic>>).map((item) => MarketplaceItem.fromJson(item)).toList();
    }
    return [];
  }

  Future<MarketplaceItem> getById(int id) async {
    final response = await _apiClient.get('/api/marketplace/$id');
    return MarketplaceItem.fromJson(response as Map<String, dynamic>);
  }

  Future<List<MarketplaceItem>> getByUsuario(int policialId) async {
    final response = await _apiClient.get('/api/marketplace/usuario/$policialId');
    if (response is List) {
      return (response as List<Map<String, dynamic>>).map((item) => MarketplaceItem.fromJson(item)).toList();
    }
    return [];
  }

  Future<MarketplaceItem> create({
    required String titulo,
    required String descricao,
    required double valor,
    required String tipo,
    required List<File> fotos,
  }) async {
    final files = <http.MultipartFile>[];
    
    for (int i = 0; i < fotos.length; i++) {
      final file = fotos[i];
      final bytes = await file.readAsBytes();
      final fileName = file.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();
      
      String contentType;
      if (extension == 'jpg' || extension == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'webp') {
        contentType = 'image/webp';
      } else {
        contentType = 'image/jpeg';
      }
      
      files.add(http.MultipartFile.fromBytes(
        'fotos',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ));
    }

    final data = {
      'titulo': titulo,
      'descricao': descricao,
      'valor': valor.toStringAsFixed(2),
      'tipo': tipo,
    };

    final response = await _apiClient.postMultipart('/api/marketplace', data, files);
    return MarketplaceItem.fromJson(response as Map<String, dynamic>);
  }

  Future<MarketplaceItem> update({
    required int id,
    String? titulo,
    String? descricao,
    double? valor,
    String? tipo,
    List<File>? fotos,
  }) async {
    final files = <http.MultipartFile>[];
    
    if (fotos != null && fotos.isNotEmpty) {
      for (int i = 0; i < fotos.length; i++) {
        final file = fotos[i];
        final bytes = await file.readAsBytes();
        final fileName = file.path.split('/').last;
        final extension = fileName.split('.').last.toLowerCase();
        
        String contentType;
        if (extension == 'jpg' || extension == 'jpeg') {
          contentType = 'image/jpeg';
        } else if (extension == 'png') {
          contentType = 'image/png';
        } else if (extension == 'webp') {
          contentType = 'image/webp';
        } else {
          contentType = 'image/jpeg';
        }
        
        files.add(http.MultipartFile.fromBytes(
          'fotos',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ));
      }
    }

    final data = <String, String>{};
    if (titulo != null) data['titulo'] = titulo;
    if (descricao != null) data['descricao'] = descricao;
    if (valor != null) data['valor'] = valor.toStringAsFixed(2);
    if (tipo != null) data['tipo'] = tipo;

    final response = files.isEmpty
        ? await _apiClient.put('/api/marketplace/$id', data)
        : await _apiClient.putMultipart('/api/marketplace/$id', data, files);
    
    return MarketplaceItem.fromJson(response as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _apiClient.delete('/api/marketplace/$id');
  }

  // Métodos de admin
  Future<List<MarketplaceItem>> getAllAdmin({String? status, int page = 1, int limit = 20}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final uri = Uri.parse('$_baseUrl/api/marketplace/admin/todos').replace(queryParameters: queryParams);
    final response = await _apiClient.get(uri.toString().replaceFirst(_baseUrl, ''));
    
    if (response is List) {
      return (response as List<Map<String, dynamic>>).map((item) => MarketplaceItem.fromJson(item)).toList();
    }
    return [];
  }

  Future<MarketplaceItem> aprovar(int id) async {
    final response = await _apiClient.put('/api/marketplace/admin/$id/aprovar', {});
    return MarketplaceItem.fromJson(response as Map<String, dynamic>);
  }

  Future<MarketplaceItem> rejeitar(int id) async {
    final response = await _apiClient.put('/api/marketplace/admin/$id/rejeitar', {});
    return MarketplaceItem.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteAdmin(int id) async {
    await _apiClient.delete('/api/marketplace/admin/$id');
  }
}

