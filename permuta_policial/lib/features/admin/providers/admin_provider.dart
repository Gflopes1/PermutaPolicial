// /lib/features/admin/providers/admin_provider.dart

import 'package:flutter/material.dart';
import '../../../core/api/repositories/admin_repository.dart';
import '../../../core/api/repositories/parceiros_repository.dart';
import '../../../core/api/repositories/consultoria_juridica_repository.dart';
import '../../../core/api/repositories/analytics_repository.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/models/consultoria_advogado.dart';

class AdminProvider with ChangeNotifier {
  final AdminRepository _adminRepository;
  final ParceirosRepository _parceirosRepository;
  final ConsultoriaJuridicaRepository _consultoriaRepository;
  final AnalyticsRepository _analyticsRepository;
  final AnalyticsService _analyticsService;

  AdminProvider(
    this._adminRepository,
    this._parceirosRepository,
    this._consultoriaRepository,
    this._analyticsRepository,
    this._analyticsService,
  );

  // Estado
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _estatisticas;
  List<Map<String, dynamic>> _sugestoes = [];
  List<Map<String, dynamic>> _verificacoes = [];
  List<Map<String, dynamic>> _verificacoesOcr = [];
  List<Map<String, dynamic>> _policiais = [];
  int _totalPoliciais = 0;
  bool _isLoadingMorePoliciais = false;
  bool _hasMorePoliciais = true;
  int _policiaisOffset = 0;
  static const int _policiaisLimit = 20;
  String? _currentSearch;
  String? _currentStatus;
  int? _currentForcaId;
  List<dynamic> _parceiros = [];
  List<ConsultoriaAdvogado> _consultoriaAdvogados = [];
  List<ConsultoriaClickStats> _consultoriaClickStats = [];
  List<ConsultoriaClickByUser> _consultoriaClicksByUser = [];
  
  // Analytics
  Map<String, dynamic>? _analyticsEstatisticas;
  final List<dynamic> _pageViewsStats = [];
  final List<dynamic> _eventosPorTipo = [];
  Map<String, dynamic>? _sessoesStats;
  final List<dynamic> _atividadePorHora = [];
  List<dynamic> _crescimentoUsuarios = [];
  List<dynamic> _contasAtivas = [];
  List<dynamic> _usuariosPorEstado = [];
  List<dynamic> _usuariosPorForca = [];
  Map<String, dynamic>? _funilPermuta;
  final List<dynamic> _demandaMunicipios = [];
  final List<dynamic> _demandaForcas = [];
  Map<String, dynamic>? _engajamentoPermuta;
  Map<String, dynamic>? _historicoIntencoes;
  bool _isLoadingAnalytics = false;
  String? _analyticsErrorMessage;
  String? _analyticsDataInicio;
  String? _analyticsDataFim;
  String _crescimentoGranularidade = 'mes';
  bool _crescimentoCumulativo = true;
  final Map<String, List<dynamic>> _crescimentoPorEstadoCache = {};
  final Map<String, List<dynamic>> _crescimentoPorForcaCache = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get estatisticas => _estatisticas;
  List<Map<String, dynamic>> get sugestoes => _sugestoes;
  List<Map<String, dynamic>> get verificacoes => _verificacoes;
  List<Map<String, dynamic>> get verificacoesOcr => _verificacoesOcr;
  List<Map<String, dynamic>> get policiais => _policiais;
  int get totalPoliciais => _totalPoliciais;
  bool get isLoadingMorePoliciais => _isLoadingMorePoliciais;
  bool get hasMorePoliciais => _hasMorePoliciais;
  List<dynamic> get parceiros => _parceiros;
  List<ConsultoriaAdvogado> get consultoriaAdvogados => _consultoriaAdvogados;
  List<ConsultoriaClickStats> get consultoriaClickStats => _consultoriaClickStats;
  List<ConsultoriaClickByUser> get consultoriaClicksByUser => _consultoriaClicksByUser;
  
  // Analytics getters
  Map<String, dynamic>? get analyticsEstatisticas => _analyticsEstatisticas;
  List<dynamic> get pageViewsStats => _pageViewsStats;
  
  // Configurações
  Map<String, dynamic>? _configuracoes;
  Map<String, dynamic>? get configuracoes => _configuracoes;
  
  // Premium Users
  List<Map<String, dynamic>> _premiumUsers = [];
  int _totalPremiumUsers = 0;
  bool _isLoadingPremiumUsers = false;
  String? _premiumUsersError;

  List<Map<String, dynamic>> _problemaRelatos = [];
  int _totalProblemaRelatos = 0;
  bool _isLoadingProblemaRelatos = false;
  String? _problemaRelatosError;
  String? _problemaRelatosStatusFilter;

  List<Map<String, dynamic>> _permutasConcluidas = [];
  bool _isLoadingPermutasConcluidas = false;
  String? _permutasConcluidasError;

  List<Map<String, dynamic>> _performanceLogs = [];
  bool _isLoadingPerformanceLogs = false;
  String? _performanceLogsError;
  String? _performanceLogsModuleFilter;
  List<Map<String, dynamic>> get premiumUsers => _premiumUsers;
  int get totalPremiumUsers => _totalPremiumUsers;
  bool get isLoadingPremiumUsers => _isLoadingPremiumUsers;
  String? get premiumUsersError => _premiumUsersError;
  List<Map<String, dynamic>> get problemaRelatos => _problemaRelatos;
  int get totalProblemaRelatos => _totalProblemaRelatos;
  bool get isLoadingProblemaRelatos => _isLoadingProblemaRelatos;
  String? get problemaRelatosError => _problemaRelatosError;
  String? get problemaRelatosStatusFilter => _problemaRelatosStatusFilter;
  List<Map<String, dynamic>> get permutasConcluidas => _permutasConcluidas;
  bool get isLoadingPermutasConcluidas => _isLoadingPermutasConcluidas;
  String? get permutasConcluidasError => _permutasConcluidasError;
  List<Map<String, dynamic>> get performanceLogs => _performanceLogs;
  bool get isLoadingPerformanceLogs => _isLoadingPerformanceLogs;
  String? get performanceLogsError => _performanceLogsError;
  String? get performanceLogsModuleFilter => _performanceLogsModuleFilter;
  List<dynamic> get eventosPorTipo => _eventosPorTipo;
  Map<String, dynamic>? get sessoesStats => _sessoesStats;
  List<dynamic> get atividadePorHora => _atividadePorHora;
  List<dynamic> get crescimentoUsuarios => _crescimentoUsuarios;
  List<dynamic> get contasAtivas => _contasAtivas;
  List<dynamic> get usuariosPorEstado => _usuariosPorEstado;
  List<dynamic> get usuariosPorForca => _usuariosPorForca;
  bool get isLoadingAnalytics => _isLoadingAnalytics;
  String? get analyticsErrorMessage => _analyticsErrorMessage;
  String? get analyticsDataInicio => _analyticsDataInicio;
  String? get analyticsDataFim => _analyticsDataFim;
  String get crescimentoGranularidade => _crescimentoGranularidade;
  bool get crescimentoCumulativo => _crescimentoCumulativo;
  Map<String, dynamic>? get funilPermuta => _funilPermuta;
  List<dynamic> get demandaMunicipios => _demandaMunicipios;
  List<dynamic> get demandaForcas => _demandaForcas;
  Map<String, dynamic>? get engajamentoPermuta => _engajamentoPermuta;
  Map<String, dynamic>? get historicoIntencoes => _historicoIntencoes;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _setLoadingAnalytics(bool value) {
    _isLoadingAnalytics = value;
    notifyListeners();
  }

  Future<void> loadEstatisticas() async {
    _setLoading(true);
    _setError(null);
    try {
      _estatisticas = await _adminRepository.getEstatisticas();
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao carregar estatísticas.');
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/admin/estatisticas', method: 'GET');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSugestoes() async {
    _setLoading(true);
    _setError(null);
    try {
      _sugestoes = await _adminRepository.getSugestoes();
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao carregar sugestões.');
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/admin/sugestoes', method: 'GET');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> aprovarSugestao(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _adminRepository.aprovarSugestao(id);
      await loadSugestoes();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao aprovar sugestão.');
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/admin/sugestoes/$id/aprovar', method: 'PUT');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejeitarSugestao(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _adminRepository.rejeitarSugestao(id);
      await loadSugestoes();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao rejeitar sugestão.');
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/admin/sugestoes/$id/rejeitar', method: 'PUT');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadVerificacoes() async {
    _setLoading(true);
    _setError(null);
    try {
      final results = await Future.wait([
        _adminRepository.getVerificacoes(),
        _adminRepository.getVerificacoesOcr(),
      ]);
      _verificacoes = results[0];
      _verificacoesOcr = results[1];
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao carregar verificações.');
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/admin/verificacoes', method: 'GET');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verificarPolicial(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _adminRepository.verificarPolicial(id);
      await loadVerificacoes();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao verificar policial.');
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/admin/policiais/$id/verificar', method: 'PUT');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejeitarPolicial(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _adminRepository.rejeitarPolicial(id);
      await loadVerificacoes();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao rejeitar policial.');
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/admin/policiais/$id/rejeitar', method: 'PUT');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> aprovarVerificacaoOcr(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _adminRepository.aprovarVerificacaoOcr(id);
      await loadVerificacoes();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao aprovar verificação OCR.');
      }
      await ErrorHandler.trackError(
        _analyticsService,
        e,
        endpoint: '/api/verificacao/ocr/pendentes/$id/aprovar',
        method: 'POST',
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejeitarVerificacaoOcr(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _adminRepository.rejeitarVerificacaoOcr(id);
      await loadVerificacoes();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao rejeitar verificação OCR.');
      }
      await ErrorHandler.trackError(
        _analyticsService,
        e,
        endpoint: '/api/verificacao/ocr/pendentes/$id/rejeitar',
        method: 'POST',
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPoliciais({String? search, String? status, int? forcaId, bool append = false}) async {
    // Se não for append, reseta tudo
    if (!append) {
      _setLoading(true);
      _policiaisOffset = 0;
      _hasMorePoliciais = true;
      _currentSearch = search;
      _currentStatus = status;
      _currentForcaId = forcaId;
    } else {
      _isLoadingMorePoliciais = true;
    }
    
    _setError(null);
    try {
      final result = await _adminRepository.getAllPoliciais(
        search: search ?? _currentSearch,
        statusVerificacao: status ?? _currentStatus,
        forcaId: forcaId ?? _currentForcaId,
        limit: _policiaisLimit,
        offset: _policiaisOffset,
      );
      
      final novosPoliciais = List<Map<String, dynamic>>.from(result['policiais'] ?? []);
      _totalPoliciais = result['total'] ?? 0;
      
      if (append) {
        _policiais.addAll(novosPoliciais);
      } else {
        _policiais = novosPoliciais;
      }
      
      _policiaisOffset = _policiais.length;
      _hasMorePoliciais = _policiais.length < _totalPoliciais;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao carregar policiais.');
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/admin/policiais', method: 'GET');
    } finally {
      _setLoading(false);
      _isLoadingMorePoliciais = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePoliciais() async {
    if (!_hasMorePoliciais || _isLoadingMorePoliciais) return;
    await loadPoliciais(append: true);
  }

  Future<Map<String, dynamic>?> loadPolicialDetalhes(int id) async {
    try {
      return await _adminRepository.getPolicialDetalhes(id);
    } catch (e) {
      await ErrorHandler.trackError(
        _analyticsService,
        e,
        endpoint: '/api/admin/policiais/$id/detalhes',
        method: 'GET',
      );
      return null;
    }
  }

  Future<bool> updatePolicial(int id, Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      await _adminRepository.updatePolicial(id, data);
      await loadPoliciais();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao atualizar policial.');
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/admin/policiais/$id', method: 'PUT');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deletePolicial(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _adminRepository.deletePolicial(id);
      await loadPoliciais();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao excluir conta.');
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/admin/policiais/$id', method: 'DELETE');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> sendBulkEmail({
    required String subject,
    required String body,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final result = await _adminRepository.sendBulkEmail(subject: subject, body: body);
      return result;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao enviar e-mails em massa.');
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/admin/email/broadcast', method: 'POST');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadParceiros() async {
    _setLoading(true);
    _setError(null);
    try {
      _parceiros = await _parceirosRepository.getAll();
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao carregar parceiros.');
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/parceiros', method: 'GET');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createParceiro(Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      await _parceirosRepository.create(data);
      await loadParceiros();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao criar parceiro.');
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/parceiros', method: 'POST');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateParceiro(int id, Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      await _parceirosRepository.update(id, data);
      await loadParceiros();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao atualizar parceiro.');
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/parceiros/$id', method: 'PUT');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteParceiro(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _parceirosRepository.delete(id);
      await loadParceiros();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao excluir parceiro.');
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/parceiros/$id', method: 'DELETE');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadConsultoriaAdvogados() async {
    _setLoading(true);
    _setError(null);
    try {
      _consultoriaAdvogados = await _consultoriaRepository.getAllAdmin();
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao carregar consultoria jurídica.');
      }
      await ErrorHandler.trackError(
        _analyticsService,
        e,
        endpoint: '/api/consultoria-juridica/admin/list',
        method: 'GET',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadConsultoriaClickStats() async {
    try {
      final data = await _consultoriaRepository.getClickStats();
      final totals = (data['totals'] as List? ?? [])
          .map((e) => ConsultoriaClickStats.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final byUser = (data['by_user'] as List? ?? [])
          .map((e) => ConsultoriaClickByUser.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _consultoriaClickStats = totals;
      _consultoriaClicksByUser = byUser;
      notifyListeners();
    } catch (e) {
      await ErrorHandler.trackError(
        _analyticsService,
        e,
        endpoint: '/api/consultoria-juridica/admin/stats',
        method: 'GET',
      );
    }
  }

  Future<bool> createConsultoriaAdvogado({
    required Map<String, String> fields,
    required List<int> photoBytes,
    String? photoFilename,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _consultoriaRepository.createAdmin(
        fields: fields,
        photoBytes: photoBytes,
        photoFilename: photoFilename,
      );
      await loadConsultoriaAdvogados();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao criar profissional.');
      }
      await ErrorHandler.trackError(
        _analyticsService,
        e,
        endpoint: '/api/consultoria-juridica/admin',
        method: 'POST',
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateConsultoriaAdvogado({
    required int id,
    required Map<String, String> fields,
    List<int>? photoBytes,
    String? photoFilename,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _consultoriaRepository.updateAdmin(
        id: id,
        fields: fields,
        photoBytes: photoBytes,
        photoFilename: photoFilename,
      );
      await loadConsultoriaAdvogados();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao atualizar profissional.');
      }
      await ErrorHandler.trackError(
        _analyticsService,
        e,
        endpoint: '/api/consultoria-juridica/admin/$id',
        method: 'PUT',
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteConsultoriaAdvogado(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _consultoriaRepository.deleteAdmin(id);
      await loadConsultoriaAdvogados();
      await loadConsultoriaClickStats();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao excluir profissional.');
      }
      await ErrorHandler.trackError(
        _analyticsService,
        e,
        endpoint: '/api/consultoria-juridica/admin/$id',
        method: 'DELETE',
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAnalytics({
    String? dataInicio,
    String? dataFim,
    String? granularidade,
    bool? cumulativo,
    bool limparPeriodo = false,
  }) async {
    _setLoadingAnalytics(true);
    _analyticsErrorMessage = null;
    if (limparPeriodo) {
      _analyticsDataInicio = null;
      _analyticsDataFim = null;
    } else {
      if (dataInicio != null) _analyticsDataInicio = dataInicio;
      if (dataFim != null) _analyticsDataFim = dataFim;
    }
    if (granularidade != null) _crescimentoGranularidade = granularidade;
    if (cumulativo != null) _crescimentoCumulativo = cumulativo;

    final inicio = _analyticsDataInicio;
    final fim = _analyticsDataFim;
    final gran = _crescimentoGranularidade;
    final cum = _crescimentoCumulativo;

    _crescimentoPorEstadoCache.clear();
    _crescimentoPorForcaCache.clear();

    try {
      final resumo = await _analyticsRepository.getResumoAdmin(
        dataInicio: inicio,
        dataFim: fim,
        granularidade: gran,
        cumulativo: cum,
      );

      _analyticsEstatisticas = Map<String, dynamic>.from(resumo['estatisticas'] ?? {});
      _sessoesStats = Map<String, dynamic>.from(resumo['sessoes'] ?? {});
      _crescimentoUsuarios = List<dynamic>.from(resumo['crescimento'] ?? []);
      _contasAtivas = List<dynamic>.from(resumo['contas_ativas'] ?? []);
      _usuariosPorEstado = List<dynamic>.from(resumo['usuarios_por_estado'] ?? []);
      _usuariosPorForca = List<dynamic>.from(resumo['usuarios_por_forca'] ?? []);
      _funilPermuta = Map<String, dynamic>.from(resumo['funil'] ?? {});
      _engajamentoPermuta = Map<String, dynamic>.from(resumo['engajamento'] ?? {});
      _analyticsErrorMessage = null;
    } catch (e) {
      debugPrint('Analytics falhou: $e');
      _analyticsErrorMessage = 'Não foi possível carregar os dados de analytics.';
    }

    notifyListeners();
    _setLoadingAnalytics(false);
  }

  Future<List<dynamic>> loadCrescimentoEstado(int estadoId) async {
    final key = '${estadoId}_$_crescimentoGranularidade$_crescimentoCumulativo';
    if (_crescimentoPorEstadoCache.containsKey(key)) {
      return _crescimentoPorEstadoCache[key]!;
    }
    final data = await _analyticsRepository.getCrescimentoUsuarios(
      dataInicio: _analyticsDataInicio,
      dataFim: _analyticsDataFim,
      granularidade: _crescimentoGranularidade,
      cumulativo: _crescimentoCumulativo,
      estadoId: estadoId,
    );
    _crescimentoPorEstadoCache[key] = data;
    notifyListeners();
    return data;
  }

  Future<List<dynamic>> loadCrescimentoForca(int forcaId) async {
    final key = '${forcaId}_$_crescimentoGranularidade$_crescimentoCumulativo';
    if (_crescimentoPorForcaCache.containsKey(key)) {
      return _crescimentoPorForcaCache[key]!;
    }
    final data = await _analyticsRepository.getCrescimentoUsuarios(
      dataInicio: _analyticsDataInicio,
      dataFim: _analyticsDataFim,
      granularidade: _crescimentoGranularidade,
      cumulativo: _crescimentoCumulativo,
      forcaId: forcaId,
    );
    _crescimentoPorForcaCache[key] = data;
    notifyListeners();
    return data;
  }

  List<dynamic>? crescimentoEstadoCached(int estadoId) {
    final key = '${estadoId}_$_crescimentoGranularidade$_crescimentoCumulativo';
    return _crescimentoPorEstadoCache[key];
  }

  List<dynamic>? crescimentoForcaCached(int forcaId) {
    final key = '${forcaId}_$_crescimentoGranularidade$_crescimentoCumulativo';
    return _crescimentoPorForcaCache[key];
  }

  Future<Map<String, dynamic>> exportMediaKitJson() async {
    return _analyticsRepository.getMediaKitExport(
      dataInicio: _analyticsDataInicio,
      dataFim: _analyticsDataFim,
    );
  }

  Future<void> loadConfiguracoes() async {
    _setLoading(true);
    _setError(null);
    try {
      _configuracoes = await _adminRepository.getConfiguracoes();
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao carregar configurações.');
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/admin/configuracoes', method: 'GET');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> updateConfiguracoes(Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      await _adminRepository.updateConfiguracoes(data);
      await loadConfiguracoes();
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao atualizar configurações.');
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/admin/configuracoes', method: 'PUT');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  bool _rebuildingGraph = false;
  bool get isRebuildingGraph => _rebuildingGraph;
  String? _rebuildGraphResult;
  String? get rebuildGraphResult => _rebuildGraphResult;

  Future<bool> rebuildPermutasInteligentesGraph() async {
    _rebuildingGraph = true;
    _rebuildGraphResult = null;
    notifyListeners();
    try {
      await _adminRepository.rebuildPermutasInteligentesGraph();
      _rebuildGraphResult =
          'Recálculo iniciado em background. Verifique os logs do servidor.';
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao recalcular mapa de grafos.');
      }
      await ErrorHandler.trackError(
        _analyticsService,
        e,
        endpoint: '/api/admin/permutas-inteligentes/rebuild-graph',
        method: 'POST',
      );
      return false;
    } finally {
      _rebuildingGraph = false;
      notifyListeners();
    }
  }

  Future<void> loadProblemaRelatos({String? status}) async {
    _isLoadingProblemaRelatos = true;
    _problemaRelatosError = null;
    _problemaRelatosStatusFilter = status;
    notifyListeners();

    try {
      final result = await _adminRepository.getProblemaRelatos(status: status);
      _problemaRelatos = List<Map<String, dynamic>>.from(result['relatos'] ?? []);
      _totalProblemaRelatos = result['total'] is int
          ? result['total'] as int
          : int.tryParse(result['total']?.toString() ?? '0') ?? 0;
    } catch (e) {
      if (e is ApiException) {
        _problemaRelatosError = e.userMessage;
      } else {
        _problemaRelatosError = 'Erro ao carregar relatos de problemas.';
      }
      await ErrorHandler.trackError(
        _analyticsService,
        e,
        endpoint: '/api/admin/problemas-relatos',
        method: 'GET',
      );
    } finally {
      _isLoadingProblemaRelatos = false;
      notifyListeners();
    }
  }

  Future<bool> atualizarProblemaRelatoStatus(
    int id, {
    required String status,
    String? resolucao,
  }) async {
    try {
      await _adminRepository.atualizarProblemaRelatoStatus(
        id,
        status: status,
        resolucao: resolucao,
      );
      await loadProblemaRelatos(status: _problemaRelatosStatusFilter);
      return true;
    } catch (e) {
      if (e is ApiException) {
        _setError(e.userMessage);
      } else {
        _setError('Erro ao atualizar relato.');
      }
      await ErrorHandler.trackError(
        _analyticsService,
        e,
        endpoint: '/api/admin/problemas-relatos/$id/status',
        method: 'PUT',
      );
      return false;
    }
  }

  Future<void> loadPermutasConcluidas() async {
    _isLoadingPermutasConcluidas = true;
    _permutasConcluidasError = null;
    notifyListeners();

    try {
      _permutasConcluidas = await _adminRepository.getPermutasConcluidas();
    } catch (e) {
      if (e is ApiException) {
        _permutasConcluidasError = e.userMessage;
      } else {
        _permutasConcluidasError = 'Erro ao carregar permutas concluídas.';
      }
      await ErrorHandler.trackError(
        _analyticsService,
        e,
        endpoint: '/api/admin/permutas-concluidas',
        method: 'GET',
      );
    } finally {
      _isLoadingPermutasConcluidas = false;
      notifyListeners();
    }
  }

  Future<void> loadPremiumUsers({String? search, String? status, String? provider}) async {
    _isLoadingPremiumUsers = true;
    _premiumUsersError = null;
    notifyListeners();
    
    try {
      final result = await _adminRepository.getPremiumUsers(
        search: search,
        status: status,
        provider: provider,
      );
      
      _premiumUsers = List<Map<String, dynamic>>.from(result['users'] ?? []);
      _totalPremiumUsers = result['total'] ?? 0;
      _premiumUsersError = null;
    } catch (e) {
      if (e is ApiException) {
        _premiumUsersError = e.userMessage;
      } else {
        _premiumUsersError = 'Erro ao carregar usuários premium.';
      }
      await ErrorHandler.trackError(_analyticsService, e, endpoint: '/api/admin/premium', method: 'GET');
    } finally {
      _isLoadingPremiumUsers = false;
      notifyListeners();
    }
  }

  Future<void> loadPerformanceLogs({String? module, int limit = 100}) async {
    _isLoadingPerformanceLogs = true;
    _performanceLogsError = null;
    _performanceLogsModuleFilter = module;
    notifyListeners();

    try {
      _performanceLogs = await _adminRepository.getPerformanceLogs(
        limit: limit,
        module: module,
      );
    } catch (e) {
      if (e is ApiException) {
        _performanceLogsError = e.userMessage;
      } else {
        _performanceLogsError = 'Erro ao carregar logs de performance.';
      }
      await ErrorHandler.trackError(
        _analyticsService,
        e,
        endpoint: '/api/admin/performance-logs',
        method: 'GET',
      );
    } finally {
      _isLoadingPerformanceLogs = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _activityLogs = [];
  bool _isLoadingActivityLogs = false;
  String? _activityLogsError;
  String? _activityLogsTipoFilter;
  int _activityLogsTotal = 0;
  int _activityLogsOffset = 0;
  static const int _activityLogsLimit = 100;
  bool _hasMoreActivityLogs = true;

  List<Map<String, dynamic>> get activityLogs => _activityLogs;
  bool get isLoadingActivityLogs => _isLoadingActivityLogs;
  String? get activityLogsError => _activityLogsError;
  int get activityLogsTotal => _activityLogsTotal;
  bool get hasMoreActivityLogs => _hasMoreActivityLogs;

  Future<void> loadActivityLogs({String? tipo, bool append = false}) async {
    if (!append) {
      _activityLogsOffset = 0;
      _hasMoreActivityLogs = true;
    }
    _isLoadingActivityLogs = true;
    _activityLogsError = null;
    _activityLogsTipoFilter = tipo;
    notifyListeners();

    try {
      final data = await _adminRepository.getActivityLogs(
        limit: _activityLogsLimit,
        offset: _activityLogsOffset,
        tipo: tipo,
      );
      final logs = List<Map<String, dynamic>>.from(
        (data['logs'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      _activityLogsTotal = (data['total'] as num?)?.toInt() ?? logs.length;
      if (append) {
        _activityLogs = [..._activityLogs, ...logs];
      } else {
        _activityLogs = logs;
      }
      _activityLogsOffset = _activityLogs.length;
      _hasMoreActivityLogs = _activityLogs.length < _activityLogsTotal;
    } catch (e) {
      if (e is ApiException) {
        _activityLogsError = e.userMessage;
      } else {
        _activityLogsError = 'Erro ao carregar log de ações.';
      }
      await ErrorHandler.trackError(
        _analyticsService,
        e,
        endpoint: '/api/admin/activity-logs',
        method: 'GET',
      );
    } finally {
      _isLoadingActivityLogs = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreActivityLogs() async {
    if (!_hasMoreActivityLogs || _isLoadingActivityLogs) return;
    await loadActivityLogs(tipo: _activityLogsTipoFilter, append: true);
  }
}

