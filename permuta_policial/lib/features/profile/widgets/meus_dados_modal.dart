// /lib/features/profile/widgets/meus_dados_modal.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/intencao.dart';
import '../../../core/config/app_styles.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/repositories/dados_repository.dart';
import '../../../shared/widgets/custom_dropdown_search.dart';
import 'gerir_intencoes_modal.dart';

class MeusDadosModal extends StatefulWidget {
  final UserProfile userProfile;
  final List<Intencao> intencoes;

  const MeusDadosModal({
    super.key,
    required this.userProfile,
    required this.intencoes,
  });

  @override
  State<MeusDadosModal> createState() => _MeusDadosModalState();
}

class _MeusDadosModalState extends State<MeusDadosModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _qsoController;
  late TextEditingController _antiguidadeController;
  bool _isSaving = false;
  
  int? _selectedForcaId;
  int? _selectedPostoId;
  List<dynamic> _forcasCache = [];
  List<dynamic> _postosCache = [];

  @override
  void initState() {
    super.initState();
    _qsoController = TextEditingController(text: widget.userProfile.qso ?? '');
    _antiguidadeController = TextEditingController(text: widget.userProfile.antiguidade ?? '');
    _selectedForcaId = widget.userProfile.forcaId;
    _selectedPostoId = widget.userProfile.postoGraduacaoId;
    _carregarDados();
  }
  
  Future<void> _carregarDados() async {
    final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
    try {
      final forcas = await dadosRepo.getForcas();
      setState(() {
        _forcasCache = forcas;
      });
      
      // Carrega postos se tiver força selecionada
      if (_selectedForcaId != null) {
        try {
          final forca = forcas.firstWhere(
            (f) => f.id == _selectedForcaId,
          );
          if (forca.tipoPermuta.isNotEmpty) {
            final postos = await dadosRepo.getPostosPorForca(forca.tipoPermuta);
            setState(() {
              _postosCache = postos;
            });
          }
        } catch (e) {
          debugPrint("Força não encontrada: $e");
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
    }
  }

  @override
  void dispose() {
    _qsoController.dispose();
    _antiguidadeController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      final updateData = <String, dynamic>{};

      // Email não pode ser editado
      if (_qsoController.text != widget.userProfile.qso) {
        updateData['qso'] = _qsoController.text;
      }
      if (_antiguidadeController.text != widget.userProfile.antiguidade) {
        updateData['antiguidade'] = _antiguidadeController.text;
      }
      if (_selectedForcaId != null && _selectedForcaId != widget.userProfile.forcaId) {
        updateData['forca_id'] = _selectedForcaId;
      }
      if (_selectedPostoId != null && _selectedPostoId != widget.userProfile.postoGraduacaoId) {
        updateData['posto_graduacao_id'] = _selectedPostoId;
      }

      if (updateData.isNotEmpty) {
        final success = await dashboardProvider.updateProfile(updateData);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppStyles.successSnackBar('Dados atualizados com sucesso!'),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppStyles.errorSnackBar('Nenhuma alteração foi feita.'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String message = 'Erro ao salvar dados.';
        if (e is ApiException) {
          message = e.userMessage;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.errorSnackBar(message),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            AppBar(
              title: const Text('Meus Dados'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dados não editáveis
                      _buildReadOnlyField('Nome', widget.userProfile.nome),
                      const SizedBox(height: 16),
                      _buildReadOnlyField('ID Funcional', widget.userProfile.idFuncional ?? 'Não informado'),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      
                      // Força editável
                      CustomDropdownSearch<dynamic>(
                        label: "Força",
                        selectedItem: _selectedForcaId != null
                            ? _forcasCache.firstWhere(
                                (f) => f.id == _selectedForcaId,
                                orElse: () => _forcasCache.isNotEmpty ? _forcasCache.first : null,
                              )
                            : null,
                        items: _forcasCache,
                        itemAsString: (f) => f?.sigla ?? f?.nome ?? 'N/A',
                        onChanged: (forca) async {
                          setState(() {
                            _selectedForcaId = forca?.id;
                            _selectedPostoId = null; // Reseta posto ao mudar força
                            _postosCache = [];
                          });
                          
                          // Carrega postos da nova força
                          if (forca != null && forca.tipoPermuta != null) {
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
                      const SizedBox(height: 16),
                      
                      // Posto/Graduação editável
                      CustomDropdownSearch<dynamic>(
                        label: "Posto/Graduação",
                        enabled: _selectedForcaId != null && _postosCache.isNotEmpty,
                        selectedItem: _postosCache.firstWhere(
                          (p) => p.id == _selectedPostoId,
                          orElse: () => null,
                        ),
                        items: _postosCache,
                        itemAsString: (p) => p.nome ?? 'N/A',
                        onChanged: (posto) {
                          setState(() {
                            _selectedPostoId = posto?.id;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      
                      // Email não editável
                      _buildReadOnlyField('Email', widget.userProfile.email ?? 'Não informado'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _qsoController,
                        decoration: const InputDecoration(
                          labelText: 'QSO (Telefone)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _antiguidadeController,
                        decoration: const InputDecoration(
                          labelText: 'Antiguidade',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Intenções
                      const Text(
                        'Intenções de Permuta',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (widget.intencoes.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Nenhuma intenção cadastrada.'),
                          ),
                        )
                      else
                        ...widget.intencoes.map((intencao) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(intencao.prioridade.toString()),
                            ),
                            title: Text(_getIntencaoDescricao(intencao)),
                            subtitle: Text('Prioridade ${intencao.prioridade}'),
                          ),
                        )),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Abre o modal de gerenciar intenções
                          final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
                          showDialog(
                            context: context,
                            builder: (ctx) => ChangeNotifierProvider.value(
                              value: dashboardProvider,
                              child: const GerirIntencoesModal(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Gerenciar Intenções'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar Alterações'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  String _getIntencaoDescricao(Intencao intencao) {
    switch (intencao.tipoIntencao) {
      case 'UNIDADE':
        return 'Unidade: ${intencao.unidadeNome ?? 'N/A'}';
      case 'MUNICIPIO':
        return 'Município: ${intencao.municipioNome ?? 'N/A'}';
      case 'ESTADO':
        return 'Estado: ${intencao.estadoSigla ?? 'N/A'}';
      default:
        return 'Tipo desconhecido';
    }
  }
}

