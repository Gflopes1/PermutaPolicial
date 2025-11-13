// /lib/features/profile/widgets/gerir_intencoes_modal.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../../../core/models/intencao.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';
import '../../../core/api/repositories/dados_repository.dart';
import '../../../shared/widgets/custom_dropdown_search.dart';
import 'sugerir_unidade_modal.dart';

/// Modelo local para gerenciar o estado do formulário dentro do modal.
class IntencaoEditModel {
  String? tipo;
  dynamic selectedEstado;
  dynamic selectedMunicipio;
  dynamic selectedUnidade;

  IntencaoEditModel();
}

class GerirIntencoesModal extends StatefulWidget {
  const GerirIntencoesModal({super.key});

  @override
  State<GerirIntencoesModal> createState() => _GerirIntencoesModalState();
}

class _GerirIntencoesModalState extends State<GerirIntencoesModal> {
  // Estado local para gerenciar o formulário
  bool _isSaving = false;
  final List<IntencaoEditModel> _intencoesState = List.generate(3, (_) => IntencaoEditModel());
  
  // Cache para melhor performance
  List<dynamic> _estadosCache = [];
  
  // Chaves para limpar os dropdowns
  final List<GlobalKey<DropdownSearchState<dynamic>>> _estadoKeys = List.generate(3, (_) => GlobalKey<DropdownSearchState<dynamic>>());
  final List<GlobalKey<DropdownSearchState<dynamic>>> _municipioKeys = List.generate(3, (_) => GlobalKey<DropdownSearchState<dynamic>>());
  final List<GlobalKey<DropdownSearchState<dynamic>>> _unidadeKeys = List.generate(3, (_) => GlobalKey<DropdownSearchState<dynamic>>());

  @override
  void initState() {
    super.initState();
    _preencherDadosExistentes();
    _carregarEstadosCache();
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
  
  void _preencherDadosExistentes() {
    // Busca as intenções já salvas do provider para pré-popular o formulário
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    List<Intencao> intencoesSalvas = provider.intencoes;

    for (var intencaoSalva in intencoesSalvas) {
      if (intencaoSalva.prioridade > 0 && intencaoSalva.prioridade <= 3) {
        int index = intencaoSalva.prioridade - 1;
        final intencaoModel = _intencoesState[index];
        
        intencaoModel.tipo = intencaoSalva.tipoIntencao;

        if (intencaoSalva.estadoId != null) {
          intencaoModel.selectedEstado = {'id': intencaoSalva.estadoId, 'sigla': intencaoSalva.estadoSigla};
        }
        if (intencaoSalva.municipioId != null) {
          intencaoModel.selectedMunicipio = {'id': intencaoSalva.municipioId, 'nome': intencaoSalva.municipioNome};
        }
        if (intencaoSalva.unidadeId != null) {
          intencaoModel.selectedUnidade = {'id': intencaoSalva.unidadeId, 'nome': intencaoSalva.unidadeNome};
        }
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
    
    if (item is Map) return item['id'] as int?;
    
    try {
      return item.id as int?;
    } catch (e) {
      return null;
    }
  }

  Future<void> _salvarIntencoes() async {
    // Usa o DashboardProvider para executar a ação de salvar
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    
    setState(() => _isSaving = true);

    final List<Map<String, dynamic>> payload = [];
    for (int i = 0; i < _intencoesState.length; i++) {
      final intencao = _intencoesState[i];
      final tipo = intencao.tipo;
      final estadoId = _getItemId(intencao.selectedEstado);
      final municipioId = _getItemId(intencao.selectedMunicipio);
      final unidadeId = _getItemId(intencao.selectedUnidade);

      if (tipo != null) {
        // Adiciona ao payload apenas as intenções válidas e preenchidas
        if ((tipo == 'ESTADO' && estadoId != null) ||
            (tipo == 'MUNICIPIO' && municipioId != null) ||
            (tipo == 'UNIDADE' && unidadeId != null)) {
          payload.add({
            "prioridade": i + 1,
            "tipo_intencao": tipo,
            "estado_id": tipo == 'ESTADO' ? estadoId : null,
            "municipio_id": tipo == 'MUNICIPIO' ? municipioId : null,
            "unidade_id": tipo == 'UNIDADE' ? unidadeId : null,
          });
        }
      }
    }

    final success = await provider.updateIntencoes(payload);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intenções salvas com sucesso!'), backgroundColor: Colors.green));
      navigator.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.initialDataError ?? 'Falha ao salvar.'), backgroundColor: Colors.red));
      setState(() => _isSaving = false);
    }
  }

  Future<void> _excluirIntencoes() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir todas as suas intenções? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSaving = true);
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    final navigator = Navigator.of(context);

    final success = await provider.deleteIntencoes();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Intenções excluídas com sucesso!'), backgroundColor: Colors.green),
      );
      navigator.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.initialDataError ?? 'Falha ao excluir.'), backgroundColor: Colors.red),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gerir Intenções de Destino'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIntencaoSlot(0),
              const Divider(height: 32, thickness: 1),
              _buildIntencaoSlot(1),
              const Divider(height: 32, thickness: 1),
              _buildIntencaoSlot(2),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(), 
          child: const Text('Cancelar')
        ),
        TextButton.icon(
          onPressed: _isSaving ? null : _excluirIntencoes,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: const Text('Excluir Todas', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _salvarIntencoes,
          child: _isSaving 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) 
            : const Text('Salvar')
        ),
      ],
    );
  }

  Widget _buildIntencaoSlot(int index) {
    final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
    final user = Provider.of<DashboardProvider>(context, listen: false).userData;
    final intencao = _intencoesState[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prioridade ${index + 1}', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        ),
        const SizedBox(height: 12),
        
        // Dropdown do Tipo de Intenção
        DropdownButtonFormField<String>(
          initialValue: intencao.tipo,
          decoration: const InputDecoration(
            labelText: 'Tipo de Intenção',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'ESTADO', child: Text('Estado')),
            DropdownMenuItem(value: 'MUNICIPIO', child: Text('Município')),
            DropdownMenuItem(value: 'UNIDADE', child: Text('Unidade Específica')),
          ],
          onChanged: (value) {
            setState(() {
              intencao.tipo = value;
              intencao.selectedEstado = null;
              intencao.selectedMunicipio = null;
              intencao.selectedUnidade = null;
              _estadoKeys[index].currentState?.clear();
              _municipioKeys[index].currentState?.clear();
              _unidadeKeys[index].currentState?.clear();
            });
          },
        ),

        if (intencao.tipo != null) ...[
          const SizedBox(height: 16),
          
          // Dropdown do Estado
          CustomDropdownSearch<dynamic>(
            key: _estadoKeys[index],
            label: "Estado",
            selectedItem: intencao.selectedEstado,
            items: _estadosCache,
            itemAsString: (e) => _getItemDisplay(e, field: 'sigla'),
            onChanged: (data) {
              setState(() {
                intencao.selectedEstado = data;
                intencao.selectedMunicipio = null;
                intencao.selectedUnidade = null;
                _municipioKeys[index].currentState?.clear();
                _unidadeKeys[index].currentState?.clear();
              });
            },
          ),
        ],

        if (intencao.tipo == 'MUNICIPIO' || intencao.tipo == 'UNIDADE') ...[
          const SizedBox(height: 16),
          
          // Dropdown do Município
          CustomDropdownSearch<dynamic>(
            key: _municipioKeys[index],
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
                _unidadeKeys[index].currentState?.clear();
              });
            },
          ),
        ],

        if (intencao.tipo == 'UNIDADE') ...[
          const SizedBox(height: 16),
          
          // Dropdown da Unidade
          CustomDropdownSearch<dynamic>(
            key: _unidadeKeys[index],
            label: "Unidade",
            enabled: intencao.selectedMunicipio != null && user != null,
            selectedItem: intencao.selectedUnidade,
            items: const [],
            asyncItems: (intencao.selectedMunicipio != null && user != null)
                ? (_) => dadosRepo.getUnidades(
                      municipioId: _getItemId(intencao.selectedMunicipio)!, 
                      forcaId: user.forcaId!
                    )
                : null,
            itemAsString: (u) => _getItemDisplay(u, field: 'nome'),
            onChanged: (data) => setState(() => intencao.selectedUnidade = data),
          ),
          
          // Botão para sugerir unidade
          if (intencao.selectedMunicipio != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  child: const Text('Não encontrou a unidade?'),
                  onPressed: () {
                    if (user == null) return;
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
        
        // Indicador visual de validação
        if (intencao.tipo != null && 
            ((intencao.tipo == 'ESTADO' && intencao.selectedEstado == null) ||
             (intencao.tipo == 'MUNICIPIO' && intencao.selectedMunicipio == null) ||
             (intencao.tipo == 'UNIDADE' && intencao.selectedUnidade == null)))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Text(
                  'Preencha todos os campos para esta intenção',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}