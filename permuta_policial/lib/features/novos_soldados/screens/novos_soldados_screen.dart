
 import 'package:flutter/material.dart';
import 'package:permuta_policial/core/api/api_exception.dart';
import 'package:permuta_policial/core/api/repositories/novos_soldados_repository.dart';
import 'package:permuta_policial/core/models/analise_vaga.dart';
import 'package:permuta_policial/core/models/dados_tela_soldado.dart';
import 'package:permuta_policial/core/models/intencoes_soldado.dart';
import 'package:permuta_policial/core/models/vaga_edital.dart';

enum SoldadoScreenStatus {
  idle,
  loading,
  saving,
  error,
}

class NovosSoldadosProvider extends ChangeNotifier {
  final NovosSoldadosRepository _repository;
  NovosSoldadosProvider(this._repository);

  SoldadoScreenStatus _status = SoldadoScreenStatus.idle;
  String? _errorMessage;
  DadosTelaSoldado? _dadosTela;

  VagaEdital? _selectedChoice1;
  VagaEdital? _selectedChoice2;
  VagaEdital? _selectedChoice3;

  // Armazena as 3 análises (sem cache global)
  AnaliseVaga? _analise1;
  AnaliseVaga? _analise2;
  AnaliseVaga? _analise3;
  
  // Estados de loading individuais
  bool _isAnalyzing1 = false;
  bool _isAnalyzing2 = false;
  bool _isAnalyzing3 = false;

  SoldadoScreenStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<VagaEdital> get vagasDisponiveis => _dadosTela?.vagasDisponiveis ?? [];
  int? get minhaPosicao => _dadosTela?.minhaPosicao;
  
  VagaEdital? get selectedChoice1 => _selectedChoice1;
  VagaEdital? get selectedChoice2 => _selectedChoice2;
  VagaEdital? get selectedChoice3 => _selectedChoice3;
  
  // Getters para análises específicas
  AnaliseVaga? get analise1 => _analise1;
  AnaliseVaga? get analise2 => _analise2;
  AnaliseVaga? get analise3 => _analise3;
  
  bool get isAnalyzing1 => _isAnalyzing1;
  bool get isAnalyzing2 => _isAnalyzing2;
  bool get isAnalyzing3 => _isAnalyzing3;

  Future<void> loadDadosTela() async {
    _setStatus(SoldadoScreenStatus.loading);
    try {
      _dadosTela = await _repository.getDadosTela();
      _preencherEscolhasSalvas();
      
      // Carrega análises para as vagas já selecionadas (sempre busca do servidor)
      await _carregarAnalisesDasEscolhas();
      
      _setStatus(SoldadoScreenStatus.idle);
    } on ApiException catch (e) {
      _setError(e.message);
    }
  }

  void updateChoice(int choiceNumber, VagaEdital? vaga) {
    switch (choiceNumber) {
      case 1:
        _selectedChoice1 = vaga;
        _analise1 = null; // Limpa análise anterior
        break;
      case 2:
        _selectedChoice2 = vaga;
        _analise2 = null;
        break;
      case 3:
        _selectedChoice3 = vaga;
        _analise3 = null;
        break;
    }
    notifyListeners();
    
    // Carrega análise automaticamente (sempre do servidor)
    if (vaga != null) {
      _analisarVagaAutomaticamente(choiceNumber, vaga.id);
    }
  }

  Future<void> salvarIntencoes() async {
    _setStatus(SoldadoScreenStatus.saving);
    try {
      await _repository.salvarIntencoes(
        opmId1: _selectedChoice1?.id,
        opmId2: _selectedChoice2?.id,
        opmId3: _selectedChoice3?.id,
      );
      
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
      
      // Recarrega as análises após salvar (dados podem ter mudado)
      await _carregarAnalisesDasEscolhas();
      
      _setStatus(SoldadoScreenStatus.idle);
    } on ApiException catch (e) {
      _setError(e.message);
    }
  }

  // Método privado para análise automática (sempre busca do servidor)
  Future<void> _analisarVagaAutomaticamente(int choiceNumber, int opmId) async {
    // Define qual flag de loading usar
    switch (choiceNumber) {
      case 1: _isAnalyzing1 = true; break;
      case 2: _isAnalyzing2 = true; break;
      case 3: _isAnalyzing3 = true; break;
    }
    notifyListeners();
    
    try {
      final analise = await _repository.analisarVaga(opmId);
      
      // Armazena no slot correto
      switch (choiceNumber) {
        case 1: _analise1 = analise; break;
        case 2: _analise2 = analise; break;
        case 3: _analise3 = analise; break;
      }
    } on ApiException catch (e) {
      debugPrint('Erro ao analisar vaga $opmId: ${e.message}');
    } finally {
      switch (choiceNumber) {
        case 1: _isAnalyzing1 = false; break;
        case 2: _isAnalyzing2 = false; break;
        case 3: _isAnalyzing3 = false; break;
      }
      notifyListeners();
    }
  }

  // Carrega análises para as 3 escolhas já salvas
  Future<void> _carregarAnalisesDasEscolhas() async {
    final futures = <Future>[];
    
    if (_selectedChoice1 != null) {
      futures.add(_analisarVagaAutomaticamente(1, _selectedChoice1!.id));
    }
    if (_selectedChoice2 != null) {
      futures.add(_analisarVagaAutomaticamente(2, _selectedChoice2!.id));
    }
    if (_selectedChoice3 != null) {
      futures.add(_analisarVagaAutomaticamente(3, _selectedChoice3!.id));
    }
    
    // Executa todas em paralelo
    await Future.wait(futures);
  }

  void _setStatus(SoldadoScreenStatus newStatus) {
    _status = newStatus;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = SoldadoScreenStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
  
  VagaEdital? _findVagaById(int? id) {
    if (id == null || _dadosTela == null) return null;
    try {
      return _dadosTela!.vagasDisponiveis.firstWhere((vaga) => vaga.id == id);
    } catch (e) {
      return null;
    }
  }
  
  void _preencherEscolhasSalvas() {
    if (_dadosTela?.minhasIntencoes != null) {
      _selectedChoice1 = _findVagaById(_dadosTela!.minhasIntencoes!.escolha1OpmId);
      _selectedChoice2 = _findVagaById(_dadosTela!.minhasIntencoes!.escolha2OpmId);
      _selectedChoice3 = _findVagaById(_dadosTela!.minhasIntencoes!.escolha3OpmId);
    }
  }
}