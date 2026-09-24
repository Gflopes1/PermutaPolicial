// /lib/features/mapa/providers/mapa_provider.dart

import 'package:flutter/material.dart';
import '../../../core/api/repositories/mapa_repository.dart';
import '../../../core/api/repositories/dados_repository.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/models/ponto_mapa.dart';
import '../../../core/models/detalhe_municipio.dart';
import '../../../core/models/estado.dart';
import '../../../core/models/forca_policial.dart';

/// Dados pré-calculados para renderização de marcadores (evita agregações no build).
class MapaMarkerViewData {
  final PontoMapa ponto;
  final int markerValue;
  final String label;

  const MapaMarkerViewData({
    required this.ponto,
    required this.markerValue,
    required this.label,
  });
}

class MapaProvider with ChangeNotifier {
  final MapaRepository _mapaRepository;
  final DadosRepository _dadosRepository;
  final AnalyticsService _analyticsService;

  MapaProvider(this._mapaRepository, this._dadosRepository, this._analyticsService);

  // --- STATE ---
  bool _isLoading = true;
  bool _isInitialDataLoading = true;
  String? _errorMessage;
  bool _shouldFitBounds = false;

  List<PontoMapa> _pontosDoMapa = [];

  /// Índice município → valor do marcador (pré-calculado ao carregar/filtrar dados).
  Map<int, int> _valueByMunicipioId = {};
  List<MapaMarkerViewData> _markerViewData = [];

  String _tipoVisualizacao = 'saindo';
  int? _estadoSelecionado;
  int? _forcaSelecionada;

  List<Estado> _estados = [];
  List<ForcaPolicial> _forcas = [];

  // --- GETTERS ---
  bool get isLoading => _isLoading;
  bool get isInitialDataLoading => _isInitialDataLoading;
  String? get errorMessage => _errorMessage;
  List<PontoMapa> get pontosDoMapa => _pontosDoMapa;
  Map<int, int> get valueByMunicipioId => _valueByMunicipioId;
  List<MapaMarkerViewData> get markerViewData => _markerViewData;
  String get tipoVisualizacao => _tipoVisualizacao;
  int? get estadoSelecionado => _estadoSelecionado;
  int? get forcaSelecionada => _forcaSelecionada;
  List<Estado> get estados => _estados;
  List<ForcaPolicial> get forcas => _forcas;
  bool get shouldFitBounds => _shouldFitBounds;

  int _markerValueForPonto(PontoMapa ponto) {
    if (_tipoVisualizacao == 'balanco') {
      return ponto.volume ?? ponto.balanco?.abs() ?? ponto.contagem;
    }
    return ponto.contagem;
  }

  String _markerLabelForPonto(PontoMapa ponto) {
    var label = (_tipoVisualizacao == 'balanco'
            ? ponto.balanco?.toString()
            : ponto.contagem.toString()) ??
        '0';
    if (_tipoVisualizacao == 'balanco' && (ponto.balanco ?? 0) > 0) {
      label = '+$label';
    }
    return label;
  }

  /// Recalcula agregações derivadas quando pontos ou tipo de visualização mudam.
  void _recomputeDerivedMapData() {
    final values = <int, int>{};
    final markers = <MapaMarkerViewData>[];

    for (final ponto in _pontosDoMapa) {
      final value = _markerValueForPonto(ponto);
      values[ponto.municipioId] = value;
      markers.add(MapaMarkerViewData(
        ponto: ponto,
        markerValue: value,
        label: _markerLabelForPonto(ponto),
      ));
    }

    _valueByMunicipioId = values;
    _markerViewData = markers;
  }

  /// Soma valores de cluster usando mapa pré-calculado (O(tamanho do cluster)).
  int sumClusterValues(Iterable<int> municipioIds) {
    var total = 0;
    for (final id in municipioIds) {
      total += _valueByMunicipioId[id] ?? 0;
    }
    return total;
  }

  Future<void> fetchInitialData() async {
    _isInitialDataLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _dadosRepository.getEstados(),
        _dadosRepository.getForcas(),
        _mapaRepository.getMapData(tipo: _tipoVisualizacao),
      ]);

      _estados = results[0] as List<Estado>;
      _forcas = results[1] as List<ForcaPolicial>;
      _pontosDoMapa = results[2] as List<PontoMapa>;
      _recomputeDerivedMapData();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/mapa', method: 'GET');
    }

    _isInitialDataLoading = false;
    _isLoading = false;
    notifyListeners();
  }

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
      _recomputeDerivedMapData();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/mapa', method: 'GET');
    }

    _isLoading = false;
    notifyListeners();
  }

  String resolveTipoDetalhe(PontoMapa ponto) {
    if (_tipoVisualizacao != 'balanco') return _tipoVisualizacao;
    final saindo = ponto.saindo ?? 0;
    final vindo = ponto.vindo ?? 0;
    if (vindo > saindo) return 'vindo';
    return 'saindo';
  }

  Future<List<DetalheMunicipio>> fetchMunicipioDetails(
    int municipioId, {
    String? tipo,
    PontoMapa? ponto,
  }) async {
    final tipoDetalhe = tipo ?? (ponto != null ? resolveTipoDetalhe(ponto) : _tipoVisualizacao);
    try {
      return await _mapaRepository.getMunicipioDetails(
        municipioId: municipioId,
        tipo: tipoDetalhe,
        estadoId: _estadoSelecionado,
        forcaId: _forcaSelecionada,
      );
    } catch (e) {
      await ErrorHandler.trackError(
        _analyticsService,
        e,
        endpoint: '/api/mapa/municipio/$municipioId',
        method: 'GET',
      );
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  void setTipoVisualizacao(String novoTipo) {
    if (_tipoVisualizacao == novoTipo) return;
    _tipoVisualizacao = novoTipo;
    _recomputeDerivedMapData();
    notifyListeners();
    fetchMapData();
  }

  void setEstado(int? estadoId) {
    if (_estadoSelecionado == estadoId) return;
    _estadoSelecionado = estadoId;
    _shouldFitBounds = estadoId != null;
    notifyListeners();
    fetchMapData();
  }

  void clearFitBoundsFlag() {
    _shouldFitBounds = false;
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
    _recomputeDerivedMapData();
    notifyListeners();
    fetchMapData();
  }
}
