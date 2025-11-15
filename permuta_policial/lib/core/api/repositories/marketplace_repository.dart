// /lib/core/api/repositories/marketplace_repository.dart

import 'dart:io';
// ignore: unnecessary_import
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
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
    
    debugPrint('getAll response type: ${response.runtimeType}');
    debugPrint('getAll response: $response');
    
    if (response is List) {
      return response.map((item) => MarketplaceItem.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<MarketplaceItem> getById(int id) async {
    final response = await _apiClient.get('/api/marketplace/$id');
    debugPrint('getById response: $response');
    return MarketplaceItem.fromJson(response as Map<String, dynamic>);
  }

  Future<List<MarketplaceItem>> getByUsuario(int policialId) async {
    final response = await _apiClient.get('/api/marketplace/usuario/$policialId');
    
    debugPrint('getByUsuario response type: ${response.runtimeType}');
    debugPrint('getByUsuario response: $response');
    
    if (response is List) {
      return response.map((item) => MarketplaceItem.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<MarketplaceItem> create({
    required String titulo,
    required String descricao,
    required double valor,
    required String tipo,
    List<File>? fotos,
    List<XFile>? fotosXFile,
  }) async {
    return await _createWithFiles(titulo, descricao, valor, tipo, fotos, fotosXFile);
  }

  Future<MarketplaceItem> _createWithFiles(
    String titulo,
    String descricao,
    double valor,
    String tipo,
    List<File>? fotos,
    List<XFile>? fotosXFile,
  ) async {
    final files = <http.MultipartFile>[];
    
    // Processa fotos File (mobile)
    if (fotos != null) {
      for (int i = 0; i < fotos.length; i++) {
        final file = fotos[i];
        final bytes = await file.readAsBytes();
        final fileName = file.path.isNotEmpty && file.path.contains('/') && !file.path.startsWith('/tmp/')
            ? file.path.split('/').last
            : 'foto_${i + 1}.jpg';
        files.add(_createMultipartFile(bytes, fileName));
      }
    }
    
    // Processa fotos XFile (web)
    if (fotosXFile != null) {
      for (int i = 0; i < fotosXFile.length; i++) {
        final xFile = fotosXFile[i];
        final bytes = await xFile.readAsBytes();
        final fileName = xFile.name.isNotEmpty ? xFile.name : 'foto_${i + 1}.jpg';
        files.add(_createMultipartFile(bytes, fileName));
      }
    }

    final data = {
      'titulo': titulo,
      'descricao': descricao,
      'valor': valor.toStringAsFixed(2),
      'tipo': tipo,
    };

    final response = await _apiClient.postMultipart('/api/marketplace', data, files);
    debugPrint('create response type: ${response.runtimeType}');
    debugPrint('create response: $response');
    
    return MarketplaceItem.fromJson(response as Map<String, dynamic>);
  }

  http.MultipartFile _createMultipartFile(Uint8List bytes, String fileName) {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    
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
    
    return http.MultipartFile.fromBytes(
      'fotos',
      bytes,
      filename: fileName,
      contentType: MediaType.parse(contentType),
    );
  }

  Future<MarketplaceItem> update({
    required int id,
    String? titulo,
    String? descricao,
    double? valor,
    String? tipo,
    List<File>? fotos,
    List<XFile>? fotosXFile,
  }) async {
    final files = <http.MultipartFile>[];
    
    // Processa fotos File (mobile)
    if (fotos != null && fotos.isNotEmpty) {
      for (int i = 0; i < fotos.length; i++) {
        final file = fotos[i];
        final bytes = await file.readAsBytes();
        final fileName = file.path.isNotEmpty && file.path.contains('/') && !file.path.startsWith('/tmp/')
            ? file.path.split('/').last
            : 'foto_${i + 1}.jpg';
        files.add(_createMultipartFile(bytes, fileName));
      }
    }
    
    // Processa fotos XFile (web)
    if (fotosXFile != null && fotosXFile.isNotEmpty) {
      for (int i = 0; i < fotosXFile.length; i++) {
        final xFile = fotosXFile[i];
        final bytes = await xFile.readAsBytes();
        final fileName = xFile.name.isNotEmpty ? xFile.name : 'foto_${i + 1}.jpg';
        files.add(_createMultipartFile(bytes, fileName));
      }
    }

    final data = <String, dynamic>{};
    if (titulo != null) data['titulo'] = titulo;
    if (descricao != null) data['descricao'] = descricao;
    if (valor != null) data['valor'] = valor.toStringAsFixed(2);
    if (tipo != null) data['tipo'] = tipo;

    final response = files.isEmpty
        ? await _apiClient.put('/api/marketplace/$id', data)
        : await _apiClient.putMultipart('/api/marketplace/$id', data, files);
    
    debugPrint('update response: $response');
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
    
    debugPrint('getAllAdmin response type: ${response.runtimeType}');
    debugPrint('getAllAdmin response: $response');
    
    if (response is List) {
      return response.map((item) => MarketplaceItem.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<MarketplaceItem> aprovar(int id) async {
    final response = await _apiClient.put('/api/marketplace/admin/$id/aprovar', {});
    debugPrint('aprovar response: $response');
    return MarketplaceItem.fromJson(response as Map<String, dynamic>);
  }

  Future<MarketplaceItem> rejeitar(int id) async {
    final response = await _apiClient.put('/api/marketplace/admin/$id/rejeitar', {});
    debugPrint('rejeitar response: $response');
    return MarketplaceItem.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteAdmin(int id) async {
    await _apiClient.delete('/api/marketplace/admin/$id');
  }
}