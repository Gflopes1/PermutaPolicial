// /lib/core/services/atualizacao_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/repositories/configuracoes_repository.dart';

class AtualizacaoService {
  final ConfiguracoesRepository _configuracoesRepository;
  final FlutterSecureStorage _storage;
  static const String _ultimaVersaoKey = 'ultima_versao_atualizacao';

  AtualizacaoService(this._configuracoesRepository)
      : _storage = const FlutterSecureStorage();

  /// Verifica se há uma nova atualização e retorna a nota se houver
  Future<String?> verificarNovaAtualizacao() async {
    try {
      final response = await _configuracoesRepository.getNotaAtualizacao();
      final nota = response['nota'] as String?;
      final versao = response['versao'] as String?;

      if (nota == null || nota.isEmpty || versao == null) {
        return null;
      }

      // Busca a última versão vista
      final ultimaVersao = await _storage.read(key: _ultimaVersaoKey);

      // Se não há versão salva ou é diferente, há nova atualização
      if (ultimaVersao != versao) {
        // Retorna a nota e a versão para serem salvas quando o diálogo for fechado
        return nota;
      }

      return null;
    } catch (e) {
      // Em caso de erro, não mostra nada
      return null;
    }
  }

  /// Marca a atualização como vista
  Future<void> marcarComoVista(String versao) async {
    await _storage.write(key: _ultimaVersaoKey, value: versao);
  }
  
  /// Obtém a versão atual da nota de atualização
  Future<String?> obterVersaoAtual() async {
    try {
      final response = await _configuracoesRepository.getNotaAtualizacao();
      return response['versao'] as String?;
    } catch (e) {
      return null;
    }
  }
}

