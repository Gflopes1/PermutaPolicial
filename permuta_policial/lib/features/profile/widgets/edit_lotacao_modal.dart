// /lib/features/profile/widgets/edit_lotacao_modal.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../../../core/models/user_profile.dart';
import '../../../core/models/forca_policial.dart';
import '../../../core/models/posto_graduacao.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';
import '../../../core/api/repositories/dados_repository.dart';
import '../../../shared/widgets/custom_dropdown_search.dart';
import 'sugerir_unidade_modal.dart';

class EditLotacaoModal extends StatefulWidget {
  final UserProfile userProfile;

  const EditLotacaoModal({super.key, required this.userProfile});

  @override
  State<EditLotacaoModal> createState() => _EditLotacaoModalState();
}

class _EditLotacaoModalState extends State<EditLotacaoModal> {
  bool _isLoading = false;
  
  late int _selectedForcaId;
  int? _selectedEstadoId;
  int? _selectedMunicipioId;
  int? _selectedUnidadeId;
  int? _selectedPostoId;
  late bool _isInterestadual;

  ForcaPolicial? _initialForca;
  PostoGraduacao? _initialPosto;
  List<ForcaPolicial> _forcasCache = [];
  List<PostoGraduacao> _postosCache = [];
  List<dynamic> _estadosCache = [];

  final _municipioKey = GlobalKey<DropdownSearchState<dynamic>>();
  final _unidadeKey = GlobalKey<DropdownSearchState<dynamic>>();
  final _postoKey = GlobalKey<DropdownSearchState<dynamic>>();
  
  @override
  void initState() {
    super.initState();
    _selectedForcaId = widget.userProfile.forcaId!;
    _selectedPostoId = widget.userProfile.postoGraduacaoId;
    _isInterestadual = widget.userProfile.lotacaoInterestadual;
    _loadInitialDropdownValues();
    
    // Carregar cache de estados após o build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarEstadosCache();
    });
  }

  Future<void> _loadInitialDropdownValues() async {
    setState(() => _isLoading = true);
    final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
    
    try {
      _forcasCache = await dadosRepo.getForcas();
      final ForcaPolicial initialForca = _forcasCache.firstWhere((f) => f.id == _selectedForcaId);
      
      PostoGraduacao? initialPosto;
      if (initialForca.tipoPermuta.isNotEmpty && _selectedPostoId != null) {
        _postosCache = await dadosRepo.getPostosPorForca(initialForca.tipoPermuta);
        initialPosto = _postosCache.firstWhere((p) => p.id == _selectedPostoId);
      }
      
      if (mounted) {
        setState(() {
          _initialForca = initialForca;
          _initialPosto = initialPosto;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar valores iniciais do dropdown: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _carregarEstadosCache() async {
    final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
    try {
      final estados = await dadosRepo.getEstados();
      setState(() {
        _estadosCache = estados;
      });
    } catch (e) {
      debugPrint("Erro ao carregar cache de estados: $e");
    }
  }
  
  Future<void> _onForcaChanged(ForcaPolicial? forca) async {
    setState(() {
      _selectedForcaId = forca?.id ?? widget.userProfile.forcaId!;
      _initialForca = forca;
      _selectedPostoId = null;
      _initialPosto = null;
      _postosCache = [];
      _postoKey.currentState?.clear();
      _selectedEstadoId = null;
      _selectedMunicipioId = null;
      _selectedUnidadeId = null;
      _municipioKey.currentState?.clear();
      _unidadeKey.currentState?.clear();
    });

    if (forca != null && forca.tipoPermuta.isNotEmpty) {
      final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
      _postosCache = await dadosRepo.getPostosPorForca(forca.tipoPermuta);
      setState(() {});
    }
  }

  Future<void> _salvarAlteracoes() async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    
    setState(() => _isLoading = true);

    final payload = <String, dynamic>{
      'lotacao_interestadual': _isInterestadual,
    };
    if (_selectedForcaId != widget.userProfile.forcaId) payload['forca_id'] = _selectedForcaId;
    if (_selectedUnidadeId != null) payload['unidade_atual_id'] = _selectedUnidadeId;
    if (_selectedPostoId != widget.userProfile.postoGraduacaoId) payload['posto_graduacao_id'] = _selectedPostoId;
    
    final success = await provider.updateProfile(payload);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado com sucesso!'), backgroundColor: Colors.green));
      navigator.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.initialDataError ?? 'Falha ao atualizar o perfil.'), backgroundColor: Colors.red));
      setState(() => _isLoading = false);
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
    
    if (item is Map) return item['id'] as int?;
    
    try {
      return item.id as int?;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
    
    return AlertDialog(
      title: const Text('Editar Perfil e Lotação'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: _isLoading && _forcasCache.isEmpty 
          ? const Center(heightFactor: 5, child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Identificação", style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  CustomDropdownSearch<ForcaPolicial>(
                    label: 'Força Policial',
                    selectedItem: _initialForca,
                    items: _forcasCache,
                    itemAsString: (f) => "${f.sigla} - ${f.nome}",
                    onChanged: _onForcaChanged,
                  ),
                  const SizedBox(height: 16),
                  CustomDropdownSearch<PostoGraduacao>(
                    key: _postoKey,
                    label: "Posto / Graduação",
                    enabled: _postosCache.isNotEmpty,
                    selectedItem: _initialPosto,
                    items: _postosCache,
                    itemAsString: (p) => p.nome,
                    onChanged: (value) => setState(() => _selectedPostoId = value?.id),
                  ),

                  const Divider(height: 32),
                  Text("Nova Lotação (Opcional)", style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  CustomDropdownSearch<dynamic>(
                    label: "Estado",
                    items: _estadosCache,
                    itemAsString: (e) => _getItemDisplay(e, field: 'sigla'),
                    onChanged: (data) => setState(() {
                      _selectedEstadoId = _getItemId(data);
                      _selectedMunicipioId = null;
                      _selectedUnidadeId = null;
                      _municipioKey.currentState?.clear();
                      _unidadeKey.currentState?.clear();
                    }),
                  ),
                  const SizedBox(height: 16),
                  CustomDropdownSearch<dynamic>(
                    key: _municipioKey,
                    label: "Município",
                    enabled: _selectedEstadoId != null,
                    items: const [],
                    asyncItems: _selectedEstadoId != null 
                        ? (_) => dadosRepo.getMunicipiosPorEstado(_selectedEstadoId!)
                        : null,
                    itemAsString: (m) => _getItemDisplay(m, field: 'nome'),
                    onChanged: (data) => setState(() {
                      _selectedMunicipioId = _getItemId(data);
                      _selectedUnidadeId = null;
                      _unidadeKey.currentState?.clear();
                    }),
                  ),
                  const SizedBox(height: 16),
                  CustomDropdownSearch<dynamic>(
                    key: _unidadeKey,
                    label: "Unidade",
                    enabled: _selectedMunicipioId != null,
                    items: const [],
                    asyncItems: _selectedMunicipioId != null
                        ? (_) => dadosRepo.getUnidades(municipioId: _selectedMunicipioId!, forcaId: _selectedForcaId)
                        : null,
                    itemAsString: (u) => _getItemDisplay(u, field: 'nome'),
                    onChanged: (data) => setState(() => _selectedUnidadeId = _getItemId(data)),
                  ),
                  if (_selectedMunicipioId != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        child: const Text('Não encontrou a unidade?'),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (ctx) => SugerirUnidadeModal(
                            municipioId: _selectedMunicipioId!, 
                            forcaId: _selectedForcaId
                          ),
                        ),
                      ),
                    ),
                  
                  const Divider(height: 24),
                  CheckboxListTile(
                    title: const Text('Aceito permuta interestadual'),
                    value: _isInterestadual,
                    onChanged: (value) => setState(() => _isInterestadual = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _isLoading ? null : _salvarAlteracoes,
          child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Salvar'),
        ),
      ],
    );
  }
}