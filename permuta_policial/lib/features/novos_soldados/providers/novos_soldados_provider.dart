import 'package:flutter/material.dart';
import 'package:permuta_policial/core/api/api_exception.dart';
import 'package:permuta_policial/core/api/repositories/novos_soldados_repository.dart';
import 'package:permuta_policial/core/models/analise_vaga.dart';
import 'package:permuta_policial/core/models/dados_tela_soldado.dart';
import 'package:permuta_policial/core/models/intencoes_soldado.dart';
import 'package:permuta_policial/core/models/vaga_edital.dart';

// Enum para gerir os diferentes estados de loading da tela
enum SoldadoScreenStatus {
  idle,    // Inativo
  loading, // Carregamento principal
  saving,  // A salvar as 3 opções
  analyzing, // A analisar uma vaga
  error,
}

class NovosSoldadosProvider extends ChangeNotifier {
  final NovosSoldadosRepository _repository;
  NovosSoldadosProvider(this._repository);

  // --- Estado Interno do Provider ---

  SoldadoScreenStatus _status = SoldadoScreenStatus.idle;
  String? _errorMessage;

  // Armazena a resposta completa da rota /dados-tela
  DadosTelaSoldado? _dadosTela;

  // Estado da UI (o que o usuário selecionou nos dropdowns)
  VagaEdital? _selectedChoice1;
  VagaEdital? _selectedChoice2;
  VagaEdital? _selectedChoice3;

  // Armazena a resposta da rota /analise-vaga
  AnaliseVaga? _analiseResult;

  // --- Getters Públicos (Lidos pela UI) ---

  SoldadoScreenStatus get status => _status;
  String? get errorMessage => _errorMessage;

  // Getters derivados de _dadosTela (agora corrigidos)
  List<VagaEdital> get vagasDisponiveis => _dadosTela?.vagasDisponiveis ?? [];
  int? get minhaPosicao => _dadosTela?.minhaPosicao;
  
  // Getters para as escolhas locais da UI
  VagaEdital? get selectedChoice1 => _selectedChoice1;
  VagaEdital? get selectedChoice2 => _selectedChoice2;
  VagaEdital? get selectedChoice3 => _selectedChoice3;
  
  AnaliseVaga? get analiseResult => _analiseResult;

  // --- Ações (Chamadas pela UI) ---

  /// Carrega todos os dados iniciais da tela (vagas e intenções salvas)
  Future<void> loadDadosTela() async {
    _setStatus(SoldadoScreenStatus.loading);
    try {
      // Busca e armazena os dados da API
      _dadosTela = await _repository.getDadosTela();

      // Pré-seleciona os dropdowns com os dados salvos
      _preencherEscolhasSalvas();

      _setStatus(SoldadoScreenStatus.idle);
    } on ApiException catch (e) {
      _setError(e.message);
    }
  }

  /// Chamado pela UI quando um dropdown muda
  void updateChoice(int choiceNumber, VagaEdital? vaga) {
    switch (choiceNumber) {
      case 1:
        _selectedChoice1 = vaga;
        break;
      case 2:
        _selectedChoice2 = vaga;
        break;
      case 3:
        _selectedChoice3 = vaga;
        break;
    }
    notifyListeners();
  }

  /// Salva as 3 intenções no backend
  Future<void> salvarIntencoes() async {
    _setStatus(SoldadoScreenStatus.saving);
    try {
      await _repository.salvarIntencoes(
        opmId1: _selectedChoice1?.id,
        opmId2: _selectedChoice2?.id,
        opmId3: _selectedChoice3?.id,
      );
      
      // Atualiza o estado local de 'intenções salvas'
      if (_dadosTela != null) {
        _dadosTela = DadosTelaSoldado(
          vagasDisponiveis: _dadosTela!.vagasDisponiveis,
          minhaPosicao: _dadosTela!.minhaPosicao,
          minhasIntencoes: IntencoesSoldado(
            escolha1OpmId: _selectedChoice1?.id,
            escolha2OpmId: _selectedChoice2?.id,
            escolha3OpmId: _selectedChoice3?.id,
          ),
        );
      }
      _setStatus(SoldadoScreenStatus.idle);
    } on ApiException catch (e) {
      _setError(e.message);
    }
  }

  /// Analisa as chances de uma vaga específica
  Future<void> analisarVaga(int opmId) async {
    _setStatus(SoldadoScreenStatus.analyzing);
    _analiseResult = null; // Limpa a análise anterior
    try {
      final analise = await _repository.analisarVaga(opmId);
      _analiseResult = analise;
      _setStatus(SoldadoScreenStatus.idle);
    } on ApiException catch (e) {
      _setError(e.message);
    }
  }

  // --- Métodos Privados (Helpers) ---

  /// Helper para definir o estado e notificar a UI
  void _setStatus(SoldadoScreenStatus newStatus) {
    _status = newStatus;
    _errorMessage = null; // Limpa erros antigos ao mudar de estado
    notifyListeners();
  }

  /// Helper para definir o estado de erro
  void _setError(String message) {
    _status = SoldadoScreenStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
  
  /// Helper para encontrar a Vaga na lista pelo ID salvo
  VagaEdital? _findVagaById(int? id) {
    if (id == null || _dadosTela == null) return null;
    try {
      // Procura na lista de vagas (agora armazenada em _dadosTela)
      return _dadosTela!.vagasDisponiveis.firstWhere((vaga) => vaga.id == id);
    } catch (e) {
      // Vaga salva não existe mais no edital (ex: vagas esgotadas e removidas)
      return null;
    }
  }
  
  /// Helper para preencher os dropdowns com dados da API
  void _preencherEscolhasSalvas() {
    if (_dadosTela?.minhasIntencoes != null) {
      _selectedChoice1 = _findVagaById(_dadosTela!.minhasIntencoes!.escolha1OpmId);
      _selectedChoice2 = _findVagaById(_dadosTela!.minhasIntencoes!.escolha2OpmId);
      _selectedChoice3 = _findVagaById(_dadosTela!.minhasIntencoes!.escolha3OpmId);
    }
  }
}