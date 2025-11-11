import 'package:permuta_policial/core/api/api_client.dart';
import 'package:permuta_policial/core/api/api_exception.dart';

// 1. IMPORTA OS NOVOS MODELS QUE ACABÁMOS DE CRIAR
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
    try {
      final response = await _apiClient.get('/novos-soldados/check-access');
      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    }
  }

  // ----------------------------------------------------
  // MÉTODO PARA BUSCAR OS DADOS DA TELA (Atualizado)
  // ----------------------------------------------------
  Future<DadosTelaSoldado> getDadosTela() async {
    try {
      final response = await _apiClient.get('/novos-soldados/dados-tela');
      
      // 2. CONVERTE O JSON NO NOSSO MODEL
      return DadosTelaSoldado.fromJson(response.data as Map<String, dynamic>);
      
    } on ApiException {
      rethrow;
    }
  }

  // ----------------------------------------------------
  // MÉTODO PARA SALVAR AS INTENÇÕES (Sem alteração no retorno)
  // ----------------------------------------------------
  Future<void> salvarIntencoes({
    int? opmId1,
    int? opmId2,
    int? opmId3,
  }) async {
    try {
      await _apiClient.post(
        '/novos-soldados/salvar-intencoes',
        {
          'escolha_1_id': opmId1,
          'escolha_2_id': opmId2,
          'escolha_3_id': opmId3,
        },
      );
    } on ApiException {
      rethrow;
    }
  }

  // ----------------------------------------------------
  // MÉTODO PARA ANALISAR UMA VAGA (Atualizado)
  // ----------------------------------------------------
  Future<AnaliseVaga> analisarVaga(int opmId) async {
    try {
      final response = await _apiClient.get('/novos-soldados/analise-vaga/$opmId');
      
      // 3. CONVERTE O JSON NO NOSSO MODEL
      return AnaliseVaga.fromJson(response.data as Map<String, dynamic>);

    } on ApiException {
      rethrow;
    }
  }
}