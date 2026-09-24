import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../../../../core/models/user_profile.dart';
import '../../../../core/models/estado.dart';
import '../../../../core/models/municipio.dart';
import '../../../../core/models/unidade.dart';
import '../../../../core/api/repositories/dados_repository.dart';
import '../../../dashboard/providers/dashboard_provider.dart';
import '../../../../shared/widgets/custom_dropdown_search.dart';
import '../sugerir_unidade_modal.dart';
import '../section_card.dart';

class LotacaoAtualSection extends StatefulWidget {
  final UserProfile userProfile;

  const LotacaoAtualSection({super.key, required this.userProfile});

  @override
  State<LotacaoAtualSection> createState() => _LotacaoAtualSectionState();
}

class _LotacaoAtualSectionState extends State<LotacaoAtualSection> {
  bool _isHydrating = true;
  bool _isLoadingEstados = true;
  Timer? _autoSaveTimer;

  int? _selectedEstadoId;
  int? _selectedMunicipioId;
  int? _selectedUnidadeId;
  List<Estado> _estadosCache = [];
  List<Municipio>? _municipiosLotacaoCache;
  List<Unidade>? _unidadesLotacaoCache;
  final _municipioLotacaoKey = GlobalKey<DropdownSearchState<Municipio>>();
  final _unidadeLotacaoKey = GlobalKey<DropdownSearchState<Unidade>>();

  @override
  void initState() {
    super.initState();
    _selectedEstadoId = widget.userProfile.estadoAtualId;
    _selectedMunicipioId = widget.userProfile.municipioAtualId;
    _selectedUnidadeId = widget.userProfile.unidadeAtualId;
    _carregarEstados();
  }

  @override
  void didUpdateWidget(covariant LotacaoAtualSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userProfile.estadoAtualId != widget.userProfile.estadoAtualId ||
        oldWidget.userProfile.municipioAtualId != widget.userProfile.municipioAtualId ||
        oldWidget.userProfile.unidadeAtualId != widget.userProfile.unidadeAtualId) {
      _selectedEstadoId = widget.userProfile.estadoAtualId;
      _selectedMunicipioId = widget.userProfile.municipioAtualId;
      _selectedUnidadeId = widget.userProfile.unidadeAtualId;
    }
  }

  Future<void> _carregarEstados() async {
    final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
    try {
      final estados = await dadosRepo.getEstados();
      if (!mounted) return;
      setState(() {
        _estadosCache = estados;
        _isLoadingEstados = false;
      });
      await _carregarLotacaoAtual(dadosRepo);
      _finishHydration();
    } catch (e) {
      debugPrint('Erro ao carregar estados: $e');
      if (mounted) {
        setState(() => _isLoadingEstados = false);
        _finishHydration();
      }
    }
  }

  void _finishHydration() {
    if (!_isHydrating) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isHydrating = false);
    });
  }

  Future<void> _carregarLotacaoAtual(DadosRepository dadosRepo) async {
    if (widget.userProfile.estadoAtualId == null) return;

    if (widget.userProfile.municipioAtualId != null) {
      try {
        final municipios = await dadosRepo.getMunicipiosPorEstado(widget.userProfile.estadoAtualId!);
        if (!mounted) return;
        setState(() => _municipiosLotacaoCache = municipios);

        if (widget.userProfile.unidadeAtualId != null && widget.userProfile.forcaId != null) {
          final unidades = await dadosRepo.getUnidades(
            municipioId: widget.userProfile.municipioAtualId!,
            forcaId: widget.userProfile.forcaId!,
          );
          if (!mounted) return;
          setState(() => _unidadesLotacaoCache = unidades);
        }
      } catch (e) {
        debugPrint('Erro ao carregar lotação: $e');
      }
    }
  }

  T? _safeFindFirst<T>(List<T> list, bool Function(T item) test) {
    for (final item in list) {
      if (test(item)) return item;
    }
    return null;
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

  void _scheduleAutoSave() {
    if (_isHydrating || !mounted) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), _autoSave);
  }

  Future<void> _autoSave() async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    final profile = widget.userProfile;
    final updateData = <String, dynamic>{};

    final unidadeChanged = _selectedUnidadeId != profile.unidadeAtualId;
    final municipioChanged = _selectedMunicipioId != profile.municipioAtualId;
    if (unidadeChanged || municipioChanged) {
      if (_selectedUnidadeId != null) {
        updateData['unidade_atual_id'] = _selectedUnidadeId;
      } else if (_selectedMunicipioId != null) {
        updateData['municipio_id'] = _selectedMunicipioId;
        updateData['unidade_atual_id'] = null;
      }
    }

    if (updateData.isNotEmpty) {
      await provider.updateProfile(updateData);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
    final forcaId = widget.userProfile.forcaId;

    return ProfileSectionCard(
      label: 'Lotação atual',
      children: [
        Stack(
          children: [
            CustomDropdownSearch<Estado>(
              label: 'Estado',
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
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        CustomDropdownSearch<Municipio>(
          key: _municipioLotacaoKey,
          label: 'Município',
          enabled: _selectedEstadoId != null,
          selectedItem: _selectedMunicipioLotacao(),
          items: _municipiosLotacaoCache ?? [],
          asyncItems: _selectedEstadoId != null && _municipiosLotacaoCache == null
              ? (_) async {
                  final municipios = await dadosRepo.getMunicipiosPorEstado(_selectedEstadoId!);
                  if (mounted) setState(() => _municipiosLotacaoCache = municipios);
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
          label: 'Unidade (Opcional)',
          enabled: _selectedMunicipioId != null && forcaId != null,
          selectedItem: _selectedUnidadeLotacao(),
          items: _unidadesLotacaoCache ?? [],
          asyncItems: (_selectedMunicipioId != null && forcaId != null && _unidadesLotacaoCache == null)
              ? (_) async {
                  final unidades = await dadosRepo.getUnidades(
                    municipioId: _selectedMunicipioId!,
                    forcaId: forcaId,
                  );
                  if (mounted) setState(() => _unidadesLotacaoCache = unidades);
                  return unidades;
                }
              : null,
          itemAsString: (u) => u.nome,
          onChanged: (data) {
            setState(() => _selectedUnidadeId = data?.id);
            _scheduleAutoSave();
          },
          onSuggestUnidade: _selectedMunicipioId != null && forcaId != null
              ? () {
                  showDialog(
                    context: context,
                    builder: (ctx) => SugerirUnidadeModal(
                      municipioId: _selectedMunicipioId!,
                      forcaId: forcaId,
                    ),
                  );
                }
              : null,
        ),
        if (_selectedMunicipioId != null && forcaId != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
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
                      forcaId: forcaId,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
