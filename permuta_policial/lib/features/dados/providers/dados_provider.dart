// /lib/features/dados/providers/dados_provider.dart

import 'package:flutter/material.dart';
import '../../../core/api/repositories/dados_repository.dart';

class DadosProvider with ChangeNotifier {
  final DadosRepository _dadosRepository;

  DadosProvider(this._dadosRepository);

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Tenta enviar uma sugestão de nova unidade para a API.
  /// Retorna a mensagem de sucesso em caso de êxito, ou null em caso de falha.
  Future<String?> sugerirUnidade({
    required String nomeSugerido,
    required int municipioId,
    required int forcaId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dadosRepository.sugerirUnidade(
        nomeSugerido: nomeSugerido,
        municipioId: municipioId,
        forcaId: forcaId,
      );
      _isLoading = false;
      notifyListeners();
      return response['message']; // Retorna a mensagem de sucesso da API
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null; // Indica que a operação falhou
    }
  }
}