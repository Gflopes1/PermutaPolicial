import 'package:permuta_policial/core/api/api_client.dart';
import 'package:permuta_policial/core/models/dados_tela_soldado.dart';
import 'package:permuta_policial/core/models/analise_vaga.dart';

class NovosSoldadosRepository {
  final ApiClient _apiClient;
  NovosSoldadosRepository(this._apiClient);

  // ----------------------------------------------------
  // MÉTODO PARA VERIFICAR O ACESSO
  // (Este pode continuar a devolver um Map, pois é simples)
  // ----------------------------------------------------
  Future<Map<String, dynamic>> checkAccess() async {
    final response = await _apiClient.get('/api/novos-soldados/check-access');
    return response as Map<String, dynamic>;
  }

  /// Busca os dados da tela (vagas disponíveis e intenções salvas)
  Future<DadosTelaSoldado> getDadosTela() async {
    final response = await _apiClient.get('/api/novos-soldados/dados-tela');
    return DadosTelaSoldado.fromJson(response as Map<String, dynamic>);
  }

  /// Salva as 3 intenções de lotação
  Future<void> salvarIntencoes({
    int? opmId1,
    int? opmId2,
    int? opmId3,
  }) async {
    await _apiClient.post(
      '/api/novos-soldados/salvar-intencoes',
      {
        'escolha_1_id': opmId1,
        'escolha_2_id': opmId2,
        'escolha_3_id': opmId3,
      },
    );
  }

  /// Analisa uma vaga específica retornando informações de competição
  Future<AnaliseVaga> analisarVaga(int opmId) async {
    final response = await _apiClient.get('/api/novos-soldados/analise-vaga/$opmId');
    return AnaliseVaga.fromJson(response as Map<String, dynamic>);
  }
}