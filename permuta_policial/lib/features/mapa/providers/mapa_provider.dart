// /lib/features/mapa/providers/mapa_provider.dart

import 'package:flutter/material.dart';
import '../../../core/api/repositories/mapa_repository.dart';
import '../../../core/api/repositories/dados_repository.dart';
import '../../../core/models/ponto_mapa.dart';
import '../../../core/models/detalhe_municipio.dart';
import '../../../core/models/estado.dart';
import '../../../core/models/forca_policial.dart';

class MapaProvider with ChangeNotifier {
  final MapaRepository _mapaRepository;
  final DadosRepository _dadosRepository;

  MapaProvider(this._mapaRepository, this._dadosRepository);

  // --- STATE ---
  bool _isLoading = true;
  bool _isInitialDataLoading = true;
  String? _errorMessage;

  // Dados do mapa
  List<PontoMapa> _pontosDoMapa = [];
  
  // Dados dos filtros
  String _tipoVisualizacao = 'saindo';
  int? _estadoSelecionado;
  int? _forcaSelecionada;

  // Opções para os filtros
  List<Estado> _estados = [];
  List<ForcaPolicial> _forcas = [];

  // --- GETTERS ---
  bool get isLoading => _isLoading;
  bool get isInitialDataLoading => _isInitialDataLoading;
  String? get errorMessage => _errorMessage;
  List<PontoMapa> get pontosDoMapa => _pontosDoMapa;
  String get tipoVisualizacao => _tipoVisualizacao;
  int? get estadoSelecionado => _estadoSelecionado;
  int? get forcaSelecionada => _forcaSelecionada;
  List<Estado> get estados => _estados;
  List<ForcaPolicial> get forcas => _forcas;

  // --- ACTIONS ---

  /// Busca os dados iniciais (filtros e os primeiros pontos do mapa).
  Future<void> fetchInitialData() async {
    _isInitialDataLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Busca as opções de filtro e os dados do mapa em paralelo
      final results = await Future.wait([
        _dadosRepository.getEstados(),
        _dadosRepository.getForcas(),
        _mapaRepository.getMapData(tipo: _tipoVisualizacao), // Busca inicial com filtros padrão
      ]);

      _estados = results[0] as List<Estado>;
      _forcas = results[1] as List<ForcaPolicial>;
      _pontosDoMapa = results[2] as List<PontoMapa>;

    } catch (e) {
      _errorMessage = e.toString();
    }
    
    _isInitialDataLoading = false;
    _isLoading = false; // A carga inicial terminou
    notifyListeners();
  }

  /// Busca apenas os dados do mapa (usado quando um filtro muda).
  Future<void> fetchMapData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pontosDoMapa = await _mapaRepository.getMapData(
        tipo: _tipoVisualizacao,
        estadoId: _estadoSelecionado,
        forcaId: _forcaSelecionada,
      );
    } catch (e) {
      _errorMessage = e.toString();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  /// Busca os detalhes de um município específico.
  Future<List<DetalheMunicipio>> fetchMunicipioDetails(int municipioId) async {
    try {
      return await _mapaRepository.getMunicipioDetails(
        municipioId: municipioId,
        tipo: _tipoVisualizacao, // Usa o tipo de visualização atual
        forcaId: _forcaSelecionada,
      );
    } catch (e) {
      // Lança o erro para que a UI possa exibi-lo (ex: num SnackBar)
      throw Exception('Falha ao buscar detalhes: ${e.toString()}');
    }
  }

  // --- MÉTODOS PARA ATUALIZAR FILTROS ---

  void setTipoVisualizacao(String novoTipo) {
    if (_tipoVisualizacao == novoTipo) return;
    _tipoVisualizacao = novoTipo;
    notifyListeners();
    fetchMapData(); // Busca os dados novamente com o novo filtro
  }

  void setEstado(int? estadoId) {
    if (_estadoSelecionado == estadoId) return;
    _estadoSelecionado = estadoId;
    notifyListeners();
    fetchMapData();
  }

  void setForca(int? forcaId) {
    if (_forcaSelecionada == forcaId) return;
    _forcaSelecionada = forcaId;
    notifyListeners();
    fetchMapData();
  }
  
  void limparFiltros() {
    _tipoVisualizacao = 'saindo';
    _estadoSelecionado = null;
    _forcaSelecionada = null;
    notifyListeners();
    fetchMapData();
  }
}