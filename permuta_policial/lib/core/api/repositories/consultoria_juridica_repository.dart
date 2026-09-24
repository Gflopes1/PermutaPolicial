import 'package:http/http.dart' as http;

import '../api_client.dart';
import '../../models/consultoria_advogado.dart';
import '../../../features/consultoria_juridica/utils/consultoria_photo_upload.dart';

class ConsultoriaJuridicaRepository {
  final ApiClient _apiClient;

  ConsultoriaJuridicaRepository(this._apiClient);

  static const _base = '/api/consultoria-juridica';

  List<T> _list<T>(dynamic response, T Function(dynamic) parse) {
    dynamic data = response;
    if (response is Map && response.containsKey('data')) {
      data = response['data'];
    }
    if (data is List) {
      return data.map((e) => parse(e)).toList();
    }
    return [];
  }

  Future<List<ConsultoriaAdvogado>> getPublicList() async {
    final response = await _apiClient.get(_base);
    return _list(response, (e) => ConsultoriaAdvogado.fromJson(Map<String, dynamic>.from(e)));
  }

  Future<ConsultoriaAdvogado> getPublicById(int id) async {
    final response = await _apiClient.get('$_base/$id');
    final data = response is Map && response.containsKey('data') ? response['data'] : response;
    return ConsultoriaAdvogado.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> registerClick(int id, String tipo) async {
    await _apiClient.post('$_base/$id/clique', {'tipo': tipo});
  }

  Future<List<ConsultoriaAdvogado>> getAllAdmin() async {
    final response = await _apiClient.get('$_base/admin/list');
    return _list(response, (e) => ConsultoriaAdvogado.fromJson(Map<String, dynamic>.from(e)));
  }

  Future<Map<String, dynamic>> getClickStats() async {
    final response = await _apiClient.get('$_base/admin/stats');
    if (response is Map && response.containsKey('data')) {
      return Map<String, dynamic>.from(response['data']);
    }
    return Map<String, dynamic>.from(response);
  }

  Future<ConsultoriaAdvogado> createAdmin({
    required Map<String, String> fields,
    required List<int> photoBytes,
    String? photoFilename,
  }) async {
    final file = buildConsultoriaPhotoMultipart(photoBytes, filename: photoFilename);
    final response = await _apiClient.postMultipart('$_base/admin', fields, [file]);
    final data = response is Map && response.containsKey('data') ? response['data'] : response;
    return ConsultoriaAdvogado.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ConsultoriaAdvogado> updateAdmin({
    required int id,
    required Map<String, String> fields,
    List<int>? photoBytes,
    String? photoFilename,
  }) async {
    final files = <http.MultipartFile>[
      if (photoBytes != null) buildConsultoriaPhotoMultipart(photoBytes, filename: photoFilename),
    ];
    final response = await _apiClient.putMultipart('$_base/admin/$id', fields, files);
    final data = response is Map && response.containsKey('data') ? response['data'] : response;
    return ConsultoriaAdvogado.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteAdmin(int id) async {
    await _apiClient.delete('$_base/admin/$id');
  }
}
