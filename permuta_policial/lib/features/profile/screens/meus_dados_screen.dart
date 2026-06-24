// /lib/features/profile/screens/meus_dados_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/user_profile.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/app_styles.dart';
import '../../../core/services/analytics_service.dart';
import '../../../shared/widgets/app_bar_helper.dart';
import '../widgets/gerir_intencoes_modal.dart';
import '../widgets/sugerir_unidade_modal.dart';
import '../../../core/api/repositories/dados_repository.dart';
import '../../../shared/widgets/custom_dropdown_search.dart';
import '../../../core/models/forca_policial.dart';
import '../../../core/models/posto_graduacao.dart';
import '../../../core/models/estado.dart';
import '../../../core/models/municipio.dart';
import '../../../core/models/unidade.dart';
import '../../../core/api/repositories/payments_repository.dart';
import '../../../shared/widgets/premium_modal.dart';
import '../../dashboard/widgets/minhas_intencoes_card.dart';
import 'package:dropdown_search/dropdown_search.dart';

class MeusDadosScreen extends StatefulWidget {
  const MeusDadosScreen({super.key});

  @override
  State<MeusDadosScreen> createState() => _MeusDadosScreenState();
}

class _MeusDadosScreenState extends State<MeusDadosScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _qsoController;
  late TextEditingController _antiguidadeController;
  bool _isSaving = false;
  bool _isHydrating = true;
  bool _intencoesDirty = false;
  Timer? _autoSaveTimer;
  String? _autoSaveFeedback;
  UserProfile? _userProfile;
  bool _ocultarNoMapa = false;
  bool _alertasMatchAtivo = true;
  bool _lotacaoInterestadual = false;
  
  // Estados de carregamento individuais
  bool _isLoadingForcas = true;
  bool _isLoadingEstados = true;
  bool _isLoadingPostos = false;
  
  // Força e Posto
  int? _selectedForcaId;
  int? _selectedPostoId;
  List<ForcaPolicial> _forcasCache = [];
  List<PostoGraduacao> _postosCache = [];
  
  // Lotação atual
  int? _selectedEstadoId;
  int? _selectedMunicipioId;
  int? _selectedUnidadeId;
  List<Estado> _estadosCache = [];
  List<Municipio>? _municipiosLotacaoCache;
  List<Unidade>? _unidadesLotacaoCache;
  final _municipioLotacaoKey = GlobalKey<DropdownSearchState<Municipio>>();
  final _unidadeLotacaoKey = GlobalKey<DropdownSearchState<Unidade>>();
  
  // Intenções de permuta
  final List<IntencaoEditModel> _intencoesState = List.generate(3, (_) => IntencaoEditModel());
  final List<GlobalKey<DropdownSearchState<dynamic>>> _estadoIntencaoKeys = List.generate(3, (_) => GlobalKey<DropdownSearchState<dynamic>>());
  final List<GlobalKey<DropdownSearchState<dynamic>>> _municipioIntencaoKeys = List.generate(3, (_) => GlobalKey<DropdownSearchState<dynamic>>());
  final List<GlobalKey<DropdownSearchState<dynamic>>> _unidadeIntencaoKeys = List.generate(3, (_) => GlobalKey<DropdownSearchState<dynamic>>());

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    _userProfile = provider.userData;
    _qsoController = TextEditingController(text: _userProfile?.qso ?? '');
    _antiguidadeController = TextEditingController(text: _userProfile?.antiguidade ?? '');
    _qsoController.addListener(_scheduleAutoSave);
    _antiguidadeController.addListener(_scheduleAutoSave);
    _ocultarNoMapa = _userProfile?.ocultarNoMapa ?? false;
    _alertasMatchAtivo = _userProfile?.alertasMatchAtivo ?? true;
    _lotacaoInterestadual = _userProfile?.lotacaoInterestadual ?? false;
    _selectedForcaId = _userProfile?.forcaId;
    _selectedPostoId = _userProfile?.postoGraduacaoId;
    
    // Carrega dados em background
    _carregarTodosOsDados();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackPageView();
    });
  }
  
  Future<void> _carregarTodosOsDados() async {
    final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
    
    // Carrega forças
    _carregarForcas(dadosRepo);
    
    // Carrega estados
    _carregarEstados(dadosRepo);
  }
  
  Future<void> _carregarForcas(DadosRepository dadosRepo) async {
    try {
      final forcas = await dadosRepo.getForcas();
      
      if (mounted) {
        setState(() {
          _forcasCache = forcas;
          _isLoadingForcas = false;
        });
        
        // Carrega postos se tiver força selecionada
        if (_selectedForcaId != null) {
          _carregarPostos(dadosRepo, forcas);
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar forças: $e");
      if (mounted) {
        setState(() {
          _isLoadingForcas = false;
        });
      }
    }
  }
  
  Future<void> _carregarPostos(DadosRepository dadosRepo, List<ForcaPolicial> forcas) async {
    try {
      final forca = forcas.firstWhere(
        (f) => f.id == _selectedForcaId,
      );
      if (forca.tipoPermuta.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingPostos = true;
          });
        }
        
        final postos = await dadosRepo.getPostosPorForca(forca.tipoPermuta);
        
        if (mounted) {
          setState(() {
            _postosCache = postos;
            _isLoadingPostos = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar postos: $e");
      if (mounted) {
        setState(() {
          _isLoadingPostos = false;
        });
      }
    }
  }
  
  Future<void> _carregarEstados(DadosRepository dadosRepo) async {
    try {
      final estados = await dadosRepo.getEstados();
      
      if (mounted) {
        setState(() {
          _estadosCache = estados;
          _isLoadingEstados = false;
        });
        
        // Carrega lotação atual após estados carregarem
        await _carregarLotacaoAtual(dadosRepo, estados);
        
        // Preenche intenções existentes
        _preencherIntencoesExistentes();
        _finishHydration();
      }
    } catch (e) {
      debugPrint("Erro ao carregar estados: $e");
      if (mounted) {
        setState(() {
          _isLoadingEstados = false;
        });
        _finishHydration();
      }
    }
  }

  void _finishHydration() {
    if (!_isHydrating) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isHydrating = false);
      }
    });
  }

  void _scheduleAutoSave() {
    if (_isHydrating || !mounted) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) _saveChanges(silent: true);
    });
  }

  void _markIntencoesDirty() {
    _intencoesDirty = true;
    _scheduleAutoSave();
  }
  
  Future<void> _carregarLotacaoAtual(DadosRepository dadosRepo, List<Estado> estados) async {
    if (_userProfile == null) return;
    
    // Preenche estado atual
    if (_userProfile!.estadoAtualId != null) {
      if (mounted) {
        setState(() {
          _selectedEstadoId = _userProfile!.estadoAtualId;
        });
      }
      
      // Preenche município atual
      if (_userProfile!.municipioAtualId != null) {
        try {
          final municipios = await dadosRepo.getMunicipiosPorEstado(_userProfile!.estadoAtualId!);
          
          if (mounted) {
            setState(() {
              _selectedMunicipioId = _userProfile!.municipioAtualId;
              _municipiosLotacaoCache = municipios;
            });
          }
          
          if (_userProfile!.unidadeAtualId != null && _selectedForcaId != null) {
            try {
              final unidades = await dadosRepo.getUnidades(
                municipioId: _userProfile!.municipioAtualId!,
                forcaId: _selectedForcaId!,
              );
              
              if (mounted) {
                setState(() {
                  _selectedUnidadeId = _userProfile!.unidadeAtualId;
                  _unidadesLotacaoCache = unidades;
                });
              }
            } catch (e) {
              debugPrint("Erro ao carregar unidades: $e");
            }
          }
        } catch (e) {
          debugPrint("Erro ao carregar municípios: $e");
        }
      }
    }
  }
  
  Estado? _getEstadoFromSelected(dynamic selected) {
    if (selected == null) return null;
    if (selected is Estado) return selected;
    if (_estadosCache.isEmpty) return null;
    final estadoId = _getItemId(selected);
    if (estadoId == null) return null;
    try {
      return _estadosCache.firstWhere(
        (e) => e.id == estadoId,
      );
    } catch (e) {
      return null;
    }
  }
  
  void _preencherIntencoesExistentes() {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    final intencoesSalvas = provider.intencoes;
    
    for (var intencaoSalva in intencoesSalvas) {
      if (intencaoSalva.prioridade > 0 && intencaoSalva.prioridade <= 3) {
        final index = intencaoSalva.prioridade - 1;
        final intencaoModel = _intencoesState[index];
        
        intencaoModel.tipo = intencaoSalva.tipoIntencao;
        
        if (intencaoSalva.estadoId != null) {
          intencaoModel.selectedEstado = _safeFindFirst(
            _estadosCache,
            (e) => e.id == intencaoSalva.estadoId,
          ) ?? {'id': intencaoSalva.estadoId, 'sigla': intencaoSalva.estadoSigla};
        }
        if (intencaoSalva.municipioId != null) {
          intencaoModel.selectedMunicipio = {'id': intencaoSalva.municipioId, 'nome': intencaoSalva.municipioNome};
        }
        if (intencaoSalva.unidadeId != null) {
          intencaoModel.selectedUnidade = {'id': intencaoSalva.unidadeId, 'nome': intencaoSalva.unidadeNome};
        }
        intencaoModel.raioKm = intencaoSalva.raioKm;
      }
    }

    if (mounted) setState(() {});
  }

  T? _safeFindFirst<T>(List<T> list, bool Function(T item) test) {
    for (final item in list) {
      if (test(item)) return item;
    }
    return null;
  }

  ForcaPolicial? _selectedForca() {
    if (_selectedForcaId == null || _forcasCache.isEmpty) return null;
    return _safeFindFirst(_forcasCache, (f) => f.id == _selectedForcaId);
  }

  PostoGraduacao? _selectedPosto() {
    if (_selectedPostoId == null || _postosCache.isEmpty) return null;
    return _safeFindFirst(_postosCache, (p) => p.id == _selectedPostoId);
  }

  Estado? _selectedEstado() {
    if (_selectedEstadoId == null || _estadosCache.isEmpty) return null;
    return _safeFindFirst(_estadosCache, (e) => e.id == _selectedEstadoId);
  }

  Municipio? _selectedMunicipioLotacao() {
    if (_selectedMunicipioId == null || _municipiosLotacaoCache == null || _municipiosLotacaoCache!.isEmpty) {
      return null;
    }
    return _safeFindFirst(_municipiosLotacaoCache!, (m) => m.id == _selectedMunicipioId);
  }

  Unidade? _selectedUnidadeLotacao() {
    if (_selectedUnidadeId == null || _unidadesLotacaoCache == null || _unidadesLotacaoCache!.isEmpty) {
      return null;
    }
    return _safeFindFirst(_unidadesLotacaoCache!, (u) => u.id == _selectedUnidadeId);
  }
  
  Future<void> _trackPageView() async {
    try {
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      await analyticsService.trackPageView('/meus-dados');
    } catch (e) {
      debugPrint('Erro ao rastrear page view de meus dados: $e');
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _qsoController.removeListener(_scheduleAutoSave);
    _antiguidadeController.removeListener(_scheduleAutoSave);
    _qsoController.dispose();
    _antiguidadeController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges({bool silent = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      if (silent) _autoSaveFeedback = 'Salvando...';
    });

    try {
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      bool hasChanges = false;
      
      // ========== ATUALIZA PERFIL ==========
      final updateData = <String, dynamic>{};

      if (_qsoController.text != (_userProfile?.qso ?? '')) {
        updateData['qso'] = _qsoController.text;
        hasChanges = true;
      }
      if (_antiguidadeController.text != (_userProfile?.antiguidade ?? '')) {
        updateData['antiguidade'] = _antiguidadeController.text;
        hasChanges = true;
      }
      if (_ocultarNoMapa != (_userProfile?.ocultarNoMapa ?? false)) {
        updateData['ocultar_no_mapa'] = _ocultarNoMapa;
        hasChanges = true;
      }
      if (_alertasMatchAtivo != (_userProfile?.alertasMatchAtivo ?? true)) {
        updateData['alertas_match_ativo'] = _alertasMatchAtivo ? 1 : 0;
        hasChanges = true;
      }
      if (_lotacaoInterestadual != (_userProfile?.lotacaoInterestadual ?? false)) {
        updateData['lotacao_interestadual'] = _lotacaoInterestadual;
        hasChanges = true;
      }
      if (_selectedForcaId != null && _selectedForcaId != _userProfile?.forcaId) {
        updateData['forca_id'] = _selectedForcaId;
        hasChanges = true;
      }
      if (_selectedPostoId != null && _selectedPostoId != _userProfile?.postoGraduacaoId) {
        updateData['posto_graduacao_id'] = _selectedPostoId;
        hasChanges = true;
      }
      
      // Lotação atual
      final unidadeChanged = _selectedUnidadeId != _userProfile?.unidadeAtualId;
      final municipioChanged = _selectedMunicipioId != _userProfile?.municipioAtualId;
      if (unidadeChanged || municipioChanged) {
        if (_selectedUnidadeId != null) {
          updateData['unidade_atual_id'] = _selectedUnidadeId;
        } else if (_selectedMunicipioId != null) {
          updateData['municipio_id'] = _selectedMunicipioId;
          updateData['unidade_atual_id'] = null;
        }
        hasChanges = true;
      }

      // Salva perfil se houver mudanças
      if (updateData.isNotEmpty) {
        final success = await dashboardProvider.updateProfile(updateData);
        if (!success) {
          if (mounted) {
            if (!silent) {
              ScaffoldMessenger.of(context).showSnackBar(
                AppStyles.errorSnackBar(dashboardProvider.initialDataError ?? 'Erro ao atualizar perfil.'),
              );
            } else {
              setState(() => _autoSaveFeedback = 'Erro ao salvar');
            }
          }
          setState(() => _isSaving = false);
          return;
        }
      }
      
      // ========== ATUALIZA INTENÇÕES ==========
      if (_intencoesDirty) {
        final List<Map<String, dynamic>> intencoesPayload = [];
        for (int i = 0; i < _intencoesState.length; i++) {
          final intencao = _intencoesState[i];
          final tipo = intencao.tipo;
          final estadoId = _getItemId(intencao.selectedEstado);
          final municipioId = _getItemId(intencao.selectedMunicipio);
          final unidadeId = _getItemId(intencao.selectedUnidade);

          if (tipo != null) {
            if ((tipo == 'ESTADO' && estadoId != null) ||
                (tipo == 'MUNICIPIO' && municipioId != null) ||
                (tipo == 'UNIDADE' && unidadeId != null)) {
              intencoesPayload.add({
                "prioridade": i + 1,
                "tipo_intencao": tipo,
                "estado_id": tipo == 'ESTADO' ? estadoId : null,
                "municipio_id": tipo == 'MUNICIPIO' ? municipioId : null,
                "unidade_id": tipo == 'UNIDADE' ? unidadeId : null,
                "raio_km": (tipo == 'MUNICIPIO' || tipo == 'UNIDADE') ? intencao.raioKm : null,
              });
            }
          }
        }

        final success = await dashboardProvider.updateIntencoes(intencoesPayload);
        if (!success) {
          if (mounted) {
            if (!silent) {
              ScaffoldMessenger.of(context).showSnackBar(
                AppStyles.errorSnackBar('Erro ao atualizar intenções.'),
              );
            } else {
              setState(() => _autoSaveFeedback = 'Erro ao salvar');
            }
          }
          setState(() => _isSaving = false);
          return;
        }
        hasChanges = true;
        _intencoesDirty = false;
      }

      if (hasChanges && mounted) {
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppStyles.successSnackBar('Dados atualizados com sucesso!'),
          );
        }
        await dashboardProvider.fetchInitialData();
        setState(() {
          _userProfile = dashboardProvider.userData;
          _autoSaveFeedback = silent ? 'Salvo' : null;
        });
      } else if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.errorSnackBar('Nenhuma alteração foi feita.'),
        );
      } else if (mounted && silent) {
        setState(() => _autoSaveFeedback = null);
      }
    } catch (e) {
      if (mounted) {
        if (!silent) {
          String message = 'Erro ao salvar dados.';
          if (e is ApiException) {
            message = e.userMessage;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            AppStyles.errorSnackBar(message),
          );
        } else {
          setState(() => _autoSaveFeedback = 'Erro ao salvar');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  String _getItemDisplay(dynamic item, {String? field}) {
    if (item == null) return 'N/A';
    
    if (item is Map) {
      return field != null ? (item[field]?.toString() ?? 'N/A') : item.toString();
    }
    
    try {
      if (field != null) {
        if (field == 'sigla') return item.sigla?.toString() ?? 'N/A';
        if (field == 'nome') return item.nome?.toString() ?? 'N/A';
        if (field == 'id') return item.id?.toString() ?? 'N/A';
      }
      return item.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  int? _getItemId(dynamic item) {
    if (item == null) return null;
    
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }
    
    if (item is Map) return parseId(item['id']);
    
    try {
      return parseId(item.id);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingForcas || _isLoadingEstados) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.of(context).pop();
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Meus Dados'),
            actions: [
              ...AppBarHelper.adicionarBotaoRelatarProblema(context),
            ],
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_userProfile == null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.of(context).pop();
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Meus Dados'),
            actions: [
              ...AppBarHelper.adicionarBotaoRelatarProblema(context),
            ],
          ),
          body: const Center(child: Text('Erro ao carregar dados do usuário.')),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Volta para a tela anterior
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meus Dados'),
          actions: [
            if (_autoSaveFeedback != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Text(
                    _autoSaveFeedback!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _autoSaveFeedback == 'Erro ao salvar'
                              ? Theme.of(context).colorScheme.error
                              : Colors.green,
                        ),
                  ),
                ),
              ),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ...AppBarHelper.adicionarBotaoRelatarProblema(context),
          ],
        ),
        body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReadOnlyField('Nome', _userProfile!.nome),
              const SizedBox(height: 16),
              _buildReadOnlyField('ID Funcional', _userProfile!.idFuncional ?? 'Não informado'),
              const SizedBox(height: 12),
              _buildSuporteContatoCard(),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              
              // Força editável
              Stack(
                children: [
                  CustomDropdownSearch<ForcaPolicial>(
                    label: "Força Policial",
                    enabled: !_isLoadingForcas,
                    selectedItem: _selectedForca(),
                items: _forcasCache,
                itemAsString: (f) => f.sigla,
                onChanged: (forca) async {
                  setState(() {
                    _selectedForcaId = forca?.id;
                    _selectedPostoId = null;
                    _postosCache = [];
                  });
                  _scheduleAutoSave();
                  
                  if (forca != null && forca.tipoPermuta.isNotEmpty) {
                    final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
                    try {
                      final postos = await dadosRepo.getPostosPorForca(forca.tipoPermuta);
                      setState(() {
                        _postosCache = postos;
                      });
                    } catch (e) {
                      debugPrint("Erro ao carregar postos: $e");
                    }
                  }
                },
                  ),
                  if (_isLoadingForcas)
                    Positioned.fill(
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Posto/Graduação editável
              Stack(
                children: [
                  CustomDropdownSearch<PostoGraduacao>(
                    label: "Posto/Graduação",
                    enabled: !_isLoadingPostos && _selectedForcaId != null && _postosCache.isNotEmpty,
                selectedItem: _selectedPosto(),
                items: _postosCache,
                itemAsString: (p) => p.nome,
                onChanged: (posto) {
                  setState(() {
                    _selectedPostoId = posto?.id;
                  });
                  _scheduleAutoSave();
                },
                  ),
                  if (_isLoadingPostos)
                    Positioned.fill(
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              
              // ========== SEÇÃO: LOTAÇÃO ATUAL ==========
              Text(
                'Lotação Atual',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildLotacaoAtualSection(),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              
              // Seção Premium
              _buildPremiumSection(context),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              
              // Email não editável
              _buildReadOnlyField('Email', _userProfile!.email ?? 'Não informado'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qsoController,
                decoration: const InputDecoration(
                  labelText: 'QSO (Telefone)',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _antiguidadeController,
                decoration: const InputDecoration(
                  labelText: 'Antiguidade',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                title: const Text('Não desejo aparecer no mapa de intenções ou enviar meu contato automaticamente quando fechar uma permuta'),
                subtitle: const Text('Mais privacidade, menos chance de encontrar uma permuta'),
                value: _ocultarNoMapa,
                onChanged: (value) {
                  setState(() => _ocultarNoMapa = value ?? false);
                  _scheduleAutoSave();
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Aceito permuta interestadual'),
                subtitle: const Text('Permite permutas entre diferentes estados'),
                value: _lotacaoInterestadual,
                onChanged: (value) {
                  setState(() => _lotacaoInterestadual = value ?? false);
                  _scheduleAutoSave();
                },
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Alertas de novos matches'),
                subtitle: const Text('Receba notificação quando surgir permuta compatível'),
                value: _alertasMatchAtivo,
                onChanged: (value) {
                  setState(() => _alertasMatchAtivo = value ?? true);
                  _scheduleAutoSave();
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              
              // ========== SEÇÃO: INTENÇÕES DE PERMUTA ==========
              Text(
                'Intenções de Permuta',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Configure até 3 intenções de permuta em ordem de prioridade',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Consumer<DashboardProvider>(
                builder: (context, dashboardProvider, _) {
                  return MinhasIntencoesCard(
                    intencoes: dashboardProvider.intencoes,
                    onRenew: () async {
                      final ok = await dashboardProvider.renewIntencoes();
                      if (ok && mounted) setState(() {});
                      return ok;
                    },
                    onPermutaConcluida: () async {
                      final ok = await dashboardProvider.markPermutaConcluida();
                      if (ok && mounted) {
                        _preencherIntencoesExistentes();
                        setState(() {});
                      }
                      return ok;
                    },
                    onEdit: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => ChangeNotifierProvider.value(
                          value: dashboardProvider,
                          child: const GerirIntencoesModal(),
                        ),
                      ).then((_) {
                        if (mounted) {
                          _preencherIntencoesExistentes();
                        }
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              ...List.generate(3, (index) => _buildIntencaoSlot(index)),
              const SizedBox(height: 16),
              Text(
                'As alterações são salvas automaticamente.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSuporteContatoCard() {
    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Para alteração de nome, e-mail, exclusão de conta ou outras solicitações cadastrais, entre em contato conosco via WhatsApp.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue.shade900,
                          height: 1.45,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openWhatsAppSuporte,
                icon: const Icon(Icons.chat),
                label: const Text('Contato via WhatsApp'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWhatsAppSuporte() async {
    final uri = Uri.parse('https://wa.me/5551986200626');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
    }
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  // ========== WIDGET: SEÇÃO LOTAÇÃO ATUAL ==========
  Widget _buildLotacaoAtualSection() {
    final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            CustomDropdownSearch<Estado>(
              label: "Estado",
              enabled: !_isLoadingEstados,
              selectedItem: _selectedEstado(),
          items: _estadosCache,
          itemAsString: (e) => e.sigla,
          onChanged: (data) {
            setState(() {
              _selectedEstadoId = data?.id;
              _selectedMunicipioId = null;
              _selectedUnidadeId = null;
              _municipiosLotacaoCache = null;
              _unidadesLotacaoCache = null;
              _municipioLotacaoKey.currentState?.clear();
              _unidadeLotacaoKey.currentState?.clear();
            });
            _scheduleAutoSave();
          },
            ),
            if (_isLoadingEstados)
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        CustomDropdownSearch<Municipio>(
          key: _municipioLotacaoKey,
          label: "Município",
          enabled: _selectedEstadoId != null,
          selectedItem: _selectedMunicipioLotacao(),
          items: _municipiosLotacaoCache ?? [],
          asyncItems: _selectedEstadoId != null && _municipiosLotacaoCache == null
              ? (_) async {
                  final municipios = await dadosRepo.getMunicipiosPorEstado(_selectedEstadoId!);
                  setState(() {
                    _municipiosLotacaoCache = municipios;
                  });
                  return municipios;
                }
              : null,
          itemAsString: (m) => m.nome,
          onChanged: (data) {
            setState(() {
              _selectedMunicipioId = data?.id;
              _selectedUnidadeId = null;
              _unidadesLotacaoCache = null;
              _unidadeLotacaoKey.currentState?.clear();
            });
            _scheduleAutoSave();
          },
        ),
        const SizedBox(height: 16),
        CustomDropdownSearch<Unidade>(
          key: _unidadeLotacaoKey,
          label: "Unidade (Opcional)",
          enabled: _selectedMunicipioId != null && _selectedForcaId != null,
          selectedItem: _selectedUnidadeLotacao(),
          items: _unidadesLotacaoCache ?? [],
          asyncItems: (_selectedMunicipioId != null && _selectedForcaId != null && _unidadesLotacaoCache == null)
              ? (_) async {
                  final unidades = await dadosRepo.getUnidades(
                    municipioId: _selectedMunicipioId!,
                    forcaId: _selectedForcaId!,
                  );
                  setState(() {
                    _unidadesLotacaoCache = unidades;
                  });
                  return unidades;
                }
              : null,
          itemAsString: (u) => u.nome,
          onChanged: (data) {
            setState(() {
              _selectedUnidadeId = data?.id;
            });
            _scheduleAutoSave();
          },
        ),
        if (_selectedMunicipioId != null && _selectedForcaId != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.help_outline, size: 16),
                label: const Text('Não encontrou a unidade?'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => SugerirUnidadeModal(
                      municipioId: _selectedMunicipioId!,
                      forcaId: _selectedForcaId!,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  // ========== WIDGET: SLOT DE INTENÇÃO ==========
  Widget _buildIntencaoSlot(int index) {
    final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
    final user = _userProfile;
    final intencao = _intencoesState[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Prioridade ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Dropdown do Tipo de Intenção
            DropdownButtonFormField<String?>(
              initialValue: intencao.tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo de Intenção',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem<String?>(value: null, child: Text('Selecione um tipo...')),
                DropdownMenuItem<String?>(value: 'ESTADO', child: Text('Estado')),
                DropdownMenuItem<String?>(value: 'MUNICIPIO', child: Text('Município')),
                DropdownMenuItem<String?>(value: 'UNIDADE', child: Text('Unidade Específica')),
              ],
              onChanged: (value) {
                setState(() {
                  intencao.tipo = value;
                  intencao.selectedEstado = null;
                  intencao.selectedMunicipio = null;
                  intencao.selectedUnidade = null;
                  intencao.raioKm = null;
                  _estadoIntencaoKeys[index].currentState?.clear();
                  _municipioIntencaoKeys[index].currentState?.clear();
                  _unidadeIntencaoKeys[index].currentState?.clear();
                });
                _markIntencoesDirty();
              },
            ),

            if (intencao.tipo != null) ...[
              const SizedBox(height: 16),
              
              // Dropdown do Estado
              CustomDropdownSearch<Estado>(
                key: _estadoIntencaoKeys[index],
                label: "Estado",
                enabled: !_isLoadingEstados,
                selectedItem: _getEstadoFromSelected(intencao.selectedEstado),
                items: _estadosCache,
                itemAsString: (e) => e.sigla,
                onChanged: (data) {
                  setState(() {
                    intencao.selectedEstado = data;
                    intencao.selectedMunicipio = null;
                    intencao.selectedUnidade = null;
                    _municipioIntencaoKeys[index].currentState?.clear();
                    _unidadeIntencaoKeys[index].currentState?.clear();
                  });
                  _markIntencoesDirty();
                },
              ),
            ],

            if (intencao.tipo == 'MUNICIPIO' || intencao.tipo == 'UNIDADE') ...[
              const SizedBox(height: 16),
              
              // Dropdown do Município
              CustomDropdownSearch<dynamic>(
                key: _municipioIntencaoKeys[index],
                label: "Município",
                enabled: intencao.selectedEstado != null,
                selectedItem: intencao.selectedMunicipio,
                items: const [],
                asyncItems: intencao.selectedEstado != null 
                    ? (_) => dadosRepo.getMunicipiosPorEstado(_getItemId(intencao.selectedEstado)!)
                    : null,
                itemAsString: (m) => _getItemDisplay(m, field: 'nome'),
                onChanged: (data) {
                  setState(() {
                    intencao.selectedMunicipio = data;
                    intencao.selectedUnidade = null;
                    _unidadeIntencaoKeys[index].currentState?.clear();
                  });
                  _markIntencoesDirty();
                },
              ),
            ],

            if (intencao.tipo == 'MUNICIPIO' || intencao.tipo == 'UNIDADE') ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: intencao.raioKm,
                decoration: const InputDecoration(
                  labelText: 'Distância aceitável',
                  helperText: 'Opcional — inclui cidades próximas na aba Próximas',
                  prefixIcon: Icon(Icons.radar),
                ),
                items: const [
                  DropdownMenuItem<int?>(value: null, child: Text('Somente destino exato')),
                  DropdownMenuItem<int?>(value: 30, child: Text('Até 30 km')),
                  DropdownMenuItem<int?>(value: 50, child: Text('Até 50 km')),
                  DropdownMenuItem<int?>(value: 80, child: Text('Até 80 km')),
                  DropdownMenuItem<int?>(value: 100, child: Text('Até 100 km')),
                  DropdownMenuItem<int?>(value: 150, child: Text('Até 150 km')),
                  DropdownMenuItem<int?>(value: 200, child: Text('Até 200 km')),
                ],
                onChanged: (value) {
                  setState(() => intencao.raioKm = value);
                  _markIntencoesDirty();
                },
              ),
            ],

            if (intencao.tipo == 'UNIDADE') ...[
              const SizedBox(height: 16),
              
              // Dropdown da Unidade
              CustomDropdownSearch<dynamic>(
                key: _unidadeIntencaoKeys[index],
                label: "Unidade",
                enabled: intencao.selectedMunicipio != null && user != null && user.forcaId != null,
                selectedItem: intencao.selectedUnidade,
                items: const [],
                asyncItems: (intencao.selectedMunicipio != null && user != null && user.forcaId != null)
                    ? (_) => dadosRepo.getUnidades(
                          municipioId: _getItemId(intencao.selectedMunicipio)!, 
                          forcaId: user.forcaId!
                        )
                    : null,
                itemAsString: (u) => _getItemDisplay(u, field: 'nome'),
                onChanged: (data) {
                  setState(() {
                    intencao.selectedUnidade = data;
                  });
                  _markIntencoesDirty();
                },
              ),
              
              // Botão para sugerir unidade
              if (intencao.selectedMunicipio != null && user != null && user.forcaId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.help_outline, size: 16),
                      label: const Text('Não encontrou a unidade?'),
                      onPressed: () {
                        final municipioId = _getItemId(intencao.selectedMunicipio);
                        if (municipioId == null) return;
                        
                        showDialog(
                          context: context,
                          builder: (ctx) => SugerirUnidadeModal(
                            municipioId: municipioId,
                            forcaId: user.forcaId!,
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSection(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium = _userProfile?.isPremium ?? false;
    final subscription = _userProfile?.subscription;

    return Card(
      color: isPremium 
          ? Colors.amber.shade50.withValues(alpha: 0.1)
          : theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: isPremium ? Colors.amber.shade400 : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status Premium',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isPremium && subscription != null) ...[
              Text(
                'Você é um membro Premium',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.amber.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subscription['end_at'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Válido até: ${_formatDate(subscription['end_at'])}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelarPremium(context),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar Premium'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Você não possui assinatura Premium',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => const PremiumModal(),
                    );
                  },
                  icon: const Icon(Icons.workspace_premium),
                  label: const Text('Assinar Premium'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is int) {
        date = DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else {
        return dateValue.toString();
      }
      
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateValue.toString();
    }
  }

  Future<void> _cancelarPremium(BuildContext context) async {
    final subscription = _userProfile?.subscription;
    if (subscription == null || subscription['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar('Não foi possível encontrar a assinatura.'),
      );
      return;
    }

    // Confirmação
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Assinatura Premium'),
        content: const Text(
          'Tem certeza que deseja cancelar sua assinatura Premium? '
          'Você perderá acesso aos recursos Premium após o período pago.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cancelando assinatura...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final paymentsRepo = Provider.of<PaymentsRepository>(context, listen: false);
      final rawId = subscription['id'];
      final subscriptionId = rawId is int ? rawId : int.parse(rawId.toString());
      
      await paymentsRepo.cancelSubscription(subscriptionId);

      if (!mounted) return;

      Navigator.of(context).pop(); // Fecha loading

      // Recarrega o perfil
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      await dashboardProvider.fetchInitialData();
      
      setState(() {
        _userProfile = dashboardProvider.userData;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.successSnackBar('Assinatura cancelada com sucesso!'),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop(); // Fecha loading

      String message = 'Erro ao cancelar assinatura.';
      if (e is ApiException) {
        message = e.userMessage;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar(message),
      );
    }
  }
}
