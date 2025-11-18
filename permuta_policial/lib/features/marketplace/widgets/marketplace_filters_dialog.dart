// /lib/features/marketplace/widgets/marketplace_filters_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api/repositories/dados_repository.dart';
import '../../../core/models/estado.dart';
import '../../../core/models/municipio.dart';
import '../../../shared/widgets/custom_dropdown_search.dart';

class MarketplaceFiltersDialog extends StatefulWidget {
  final String? tipoInicial;
  final String? estadoInicial;
  final String? cidadeInicial;

  const MarketplaceFiltersDialog({
    super.key,
    this.tipoInicial,
    this.estadoInicial,
    this.cidadeInicial,
  });

  @override
  State<MarketplaceFiltersDialog> createState() => 
      _MarketplaceFiltersDialogState();
}

class _MarketplaceFiltersDialogState extends State<MarketplaceFiltersDialog> {
  String? _tipoSelecionado;
  String? _estadoSelecionado;
  String? _cidadeSelecionada;
  
  List<Estado> _estados = [];
  List<Municipio> _cidades = [];
  bool _loadingEstados = false;
  bool _loadingCidades = false;

  @override
  void initState() {
    super.initState();
    _tipoSelecionado = widget.tipoInicial;
    _estadoSelecionado = widget.estadoInicial;
    _cidadeSelecionada = widget.cidadeInicial;
    _carregarEstados();
  }

  Future<void> _carregarEstados() async {
    setState(() => _loadingEstados = true);
    try {
      final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
      final estados = await dadosRepo.getEstados();
      if (mounted) {
        setState(() {
          _estados = estados;
          _loadingEstados = false;
        });
        // Se já havia um estado selecionado, carregar as cidades
        if (_estadoSelecionado != null) {
          _carregarCidades(_estadoSelecionado!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingEstados = false);
      }
    }
  }

  Future<void> _carregarCidades(String estadoSigla) async {
    setState(() {
      _loadingCidades = true;
      _cidades = [];
      _cidadeSelecionada = null;
    });

    try {
      // Buscar ID do estado pela sigla
      final estado = _estados.firstWhere(
        (e) => e.sigla == estadoSigla,
      );

      final dadosRepo = Provider.of<DadosRepository>(context, listen: false);
      final cidades = await dadosRepo.getMunicipiosPorEstado(estado.id);
      
      if (mounted) {
        setState(() {
          _cidades = cidades;
          _loadingCidades = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCidades = false);
      }
    }
  }

  void _aplicarFiltros() {
    Navigator.of(context).pop({
      'tipo': _tipoSelecionado,
      'estado': _estadoSelecionado,
      'cidade': _cidadeSelecionada,
    });
  }

  void _limparFiltros() {
    setState(() {
      _tipoSelecionado = null;
      _estadoSelecionado = null;
      _cidadeSelecionada = null;
      _cidades = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Filtrar Anúncios',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Conteúdo
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo
                    Text(
                      'Tipo de Item',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTipoChips(theme),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    
                    // Estado
                    Text(
                      'Estado',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_loadingEstados)
                      const Center(child: CircularProgressIndicator())
                    else
                      CustomDropdownSearch<Estado>(
                        label: 'Selecione um estado',
                        selectedItem: () {
                          if (_estadoSelecionado == null) return null;
                          final encontrado = _estados.where((e) => e.sigla == _estadoSelecionado);
                          return encontrado.isNotEmpty ? encontrado.first : null;
                        }(),
                        items: _estados,
                        itemAsString: (estado) => '${estado.sigla} - ${estado.nome}',
                        onChanged: (estado) {
                          setState(() {
                            _estadoSelecionado = estado?.sigla;
                            if (estado != null) {
                              _carregarCidades(estado.sigla);
                            } else {
                              _cidades = [];
                              _cidadeSelecionada = null;
                            }
                          });
                        },
                      ),
                    
                    // Cidade
                    if (_estadoSelecionado != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Cidade',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingCidades)
                        const Center(child: CircularProgressIndicator())
                      else if (_cidades.isEmpty)
                        const Text('Nenhuma cidade disponível')
                      else
                        CustomDropdownSearch<Municipio>(
                          label: 'Selecione uma cidade',
                          selectedItem: () {
                            if (_cidadeSelecionada == null) return null;
                            final encontrado = _cidades.where((c) => c.nome == _cidadeSelecionada);
                            return encontrado.isNotEmpty ? encontrado.first : null;
                          }(),
                          items: _cidades,
                          itemAsString: (cidade) => cidade.nome,
                          onChanged: (cidade) {
                            setState(() {
                              _cidadeSelecionada = cidade?.nome;
                            });
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ),

            // Ações
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _limparFiltros,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Limpar Filtros'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _aplicarFiltros,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoChips(ThemeData theme) {
    final tipos = [
      {'value': 'armas', 'label': 'Armas', 'icon': Icons.gpp_maybe},
      {'value': 'veiculos', 'label': 'Veículos', 'icon': Icons.directions_car},
      {'value': 'equipamentos', 'label': 'Equipamentos', 'icon': Icons.work_outline},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tipos.map((tipo) {
        final isSelected = _tipoSelecionado == tipo['value'];
        return FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tipo['icon'] as IconData,
                size: 18,
                color: isSelected ? Colors.white : null,
              ),
              const SizedBox(width: 6),
              Text(tipo['label'] as String),
            ],
          ),
          onSelected: (selected) {
            setState(() {
              _tipoSelecionado = selected ? tipo['value'] as String : null;
            });
          },
          selectedColor: theme.primaryColor,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : null,
          ),
        );
      }).toList(),
    );
  }
}