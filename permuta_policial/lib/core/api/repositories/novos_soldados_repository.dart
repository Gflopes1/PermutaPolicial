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
  // ----------------------------------------------------
  Future<Map<String, dynamic>> checkAccess() async {
    try {
      // === CORREÇÃO: Adicionado /api ===
      final response = await _apiClient.get('/api/novos-soldados/check-access');
      return response as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    }
  }

  // ----------------------------------------------------
  // MÉTODO PARA BUSCAR OS DADOS DA TELA (Atualizado)
  // ----------------------------------------------------
  Future<DadosTelaSoldado> getDadosTela() async {
    try {
      // === CORREÇÃO: Adicionado /api ===
      final response = await _apiClient.get('/api/novos-soldados/dados-tela');
      
      return DadosTelaSoldado.fromJson(response as Map<String, dynamic>);
      
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
      // === CORREÇÃO: Adicionado /api ===
      await _apiClient.post(
        '/api/novos-soldados/salvar-intencoes',
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
      // === CORREÇÃO: Adicionado /api ===
      final response = await _apiClient.get('/api/novos-soldados/analise-vaga/$opmId');
      
      return AnaliseVaga.fromJson(response as Map<String, dynamic>);

    } on ApiException {
      rethrow;
    }
  }
}