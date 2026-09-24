import '../api_client.dart';
import '../../models/analise_vaga.dart';
import '../../models/dados_tela_soldado.dart';
import '../../models/edital_resumo.dart';

class EditaisRepository {
  final ApiClient _apiClient;
  EditaisRepository(this._apiClient);

  Future<Map<String, dynamic>> getWhatsappConfig() async {
    final response = await _apiClient.get('/api/editais/whatsapp-config');
    return response as Map<String, dynamic>;
  }

  Future<List<EditalResumo>> listEditais({required String aba}) async {
    final response = await _apiClient.get('/api/editais?aba=$aba');
    final list = response as List<dynamic>;
    return list.map((e) => EditalResumo.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<EditalDetalhe> getEdital(int id) async {
    final response = await _apiClient.get('/api/editais/$id');
    return EditalDetalhe.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<DadosTelaSoldado> getDadosTela(int editalId) async {
    final response = await _apiClient.get('/api/editais/$editalId/dados-tela');
    return DadosTelaSoldado.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<void> salvarIntencoes(int editalId, {int? opmId1, int? opmId2, int? opmId3}) async {
    await _apiClient.post('/api/editais/$editalId/intencoes', {
      'escolha_1_id': opmId1,
      'escolha_2_id': opmId2,
      'escolha_3_id': opmId3,
    });
  }

  Future<AnaliseVaga> analisarVaga(int editalId, int vagaId) async {
    final response = await _apiClient.get('/api/editais/$editalId/analise-vaga/$vagaId');
    return AnaliseVaga.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<Map<String, dynamic>> resumoPublico(int editalId) async {
    final response = await _apiClient.get('/api/editais/$editalId/publico');
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> consultaPublica(int editalId, String idFuncional) async {
    final encoded = Uri.encodeQueryComponent(idFuncional.trim());
    final response = await _apiClient.get(
      '/api/editais/$editalId/consulta-publica?id_funcional=$encoded',
    );
    return Map<String, dynamic>.from(response as Map);
  }

  // Admin
  Future<List<Map<String, dynamic>>> adminListEditais() async {
    final response = await _apiClient.get('/api/admin/editais');
    if (response is! List) {
      throw FormatException('Resposta inválida ao listar editais');
    }
    return response.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> adminCreateEdital(Map<String, dynamic> data) async {
    return Map<String, dynamic>.from(
      await _apiClient.post('/api/admin/editais', data) as Map,
    );
  }

  Future<Map<String, dynamic>> adminUpdateEdital(int id, Map<String, dynamic> data) async {
    return Map<String, dynamic>.from(
      await _apiClient.put('/api/admin/editais/$id', data) as Map,
    );
  }

  Future<void> adminDeleteEdital(int id) async {
    await _apiClient.delete('/api/admin/editais/$id');
  }

  Future<Map<String, dynamic>> adminImportVagas(int id, String csv, {String modo = 'substituir'}) async {
    return Map<String, dynamic>.from(
      await _apiClient.post('/api/admin/editais/$id/importar-vagas', {'csv': csv, 'modo': modo}) as Map,
    );
  }

  Future<Map<String, dynamic>> adminImportParticipantes(int id, String csv, {String modo = 'substituir'}) async {
    return Map<String, dynamic>.from(
      await _apiClient.post('/api/admin/editais/$id/importar-participantes', {'csv': csv, 'modo': modo}) as Map,
    );
  }
}
