import 'package:flutter/material.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/repositories/editais_repository.dart';
import '../../../core/models/analise_vaga.dart';
import '../../../core/models/dados_tela_soldado.dart';
import '../../../core/models/intencoes_soldado.dart';
import '../../../core/models/vaga_edital.dart';

enum EditalSimuladorStatus { idle, loading, saving, error }

class EditalSimuladorProvider extends ChangeNotifier {
  final EditaisRepository _repository;
  final int editalId;

  EditalSimuladorProvider(this._repository, this.editalId);

  EditalSimuladorStatus _status = EditalSimuladorStatus.idle;
  String? _errorMessage;
  DadosTelaSoldado? _dadosTela;

  VagaEdital? _selectedChoice1;
  VagaEdital? _selectedChoice2;
  VagaEdital? _selectedChoice3;

  AnaliseVaga? _analise1;
  AnaliseVaga? _analise2;
  AnaliseVaga? _analise3;

  bool _isAnalyzing1 = false;
  bool _isAnalyzing2 = false;
  bool _isAnalyzing3 = false;

  EditalSimuladorStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<VagaEdital> get vagasDisponiveis => _dadosTela?.vagasDisponiveis ?? [];
  int? get minhaPosicao => _dadosTela?.minhaPosicao;
  int get totalIntencoesRegistradas => _dadosTela?.totalIntencoesRegistradas ?? 0;
  VagaEdital? get selectedChoice1 => _selectedChoice1;
  VagaEdital? get selectedChoice2 => _selectedChoice2;
  VagaEdital? get selectedChoice3 => _selectedChoice3;
  AnaliseVaga? get analise1 => _analise1;
  AnaliseVaga? get analise2 => _analise2;
  AnaliseVaga? get analise3 => _analise3;
  bool get isAnalyzing1 => _isAnalyzing1;
  bool get isAnalyzing2 => _isAnalyzing2;
  bool get isAnalyzing3 => _isAnalyzing3;

  Future<void> loadDadosTela() async {
    _status = EditalSimuladorStatus.loading;
    notifyListeners();
    try {
      _dadosTela = await _repository.getDadosTela(editalId);
      _preencherEscolhasSalvas();
      await _carregarAnalisesDasEscolhas();
      _status = EditalSimuladorStatus.idle;
      _errorMessage = null;
    } on ApiException catch (e) {
      _status = EditalSimuladorStatus.error;
      _errorMessage = e.message;
    }
    notifyListeners();
  }

  void updateChoice(int choiceNumber, VagaEdital? vaga) {
    switch (choiceNumber) {
      case 1:
        _selectedChoice1 = vaga;
        _analise1 = null;
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
    if (vaga != null) {
      _analisarVagaAutomaticamente(choiceNumber, vaga.id);
    }
  }

  Future<void> salvarIntencoes() async {
    _status = EditalSimuladorStatus.saving;
    notifyListeners();
    try {
      await _repository.salvarIntencoes(
        editalId,
        opmId1: _selectedChoice1?.id,
        opmId2: _selectedChoice2?.id,
        opmId3: _selectedChoice3?.id,
      );
      if (_dadosTela != null) {
        int totalAtualizado = _dadosTela!.totalIntencoesRegistradas;
        try {
          final refreshed = await _repository.getDadosTela(editalId);
          totalAtualizado = refreshed.totalIntencoesRegistradas;
        } catch (_) {}
        _dadosTela = DadosTelaSoldado(
          vagasDisponiveis: _dadosTela!.vagasDisponiveis,
          minhaPosicao: _dadosTela!.minhaPosicao,
          totalIntencoesRegistradas: totalAtualizado,
          minhasIntencoes: IntencoesSoldado(
            escolha1OpmId: _selectedChoice1?.id,
            escolha2OpmId: _selectedChoice2?.id,
            escolha3OpmId: _selectedChoice3?.id,
          ),
        );
      }
      await _carregarAnalisesDasEscolhas();
      _status = EditalSimuladorStatus.idle;
    } on ApiException catch (e) {
      _status = EditalSimuladorStatus.error;
      _errorMessage = e.message;
    }
    notifyListeners();
  }

  Future<void> _analisarVagaAutomaticamente(int choiceNumber, int vagaId) async {
    switch (choiceNumber) {
      case 1:
        _isAnalyzing1 = true;
        break;
      case 2:
        _isAnalyzing2 = true;
        break;
      case 3:
        _isAnalyzing3 = true;
        break;
    }
    notifyListeners();

    try {
      final analise = await _repository.analisarVaga(editalId, vagaId);
      switch (choiceNumber) {
        case 1:
          _analise1 = analise;
          break;
        case 2:
          _analise2 = analise;
          break;
        case 3:
          _analise3 = analise;
          break;
      }
    } on ApiException catch (e) {
      debugPrint('Erro ao analisar vaga $vagaId: ${e.message}');
    } finally {
      switch (choiceNumber) {
        case 1:
          _isAnalyzing1 = false;
          break;
        case 2:
          _isAnalyzing2 = false;
          break;
        case 3:
          _isAnalyzing3 = false;
          break;
      }
      notifyListeners();
    }
  }

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
    await Future.wait(futures);
  }

  VagaEdital? _findVagaById(int? id) {
    if (id == null || _dadosTela == null) return null;
    try {
      return _dadosTela!.vagasDisponiveis.firstWhere((vaga) => vaga.id == id);
    } catch (_) {
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
