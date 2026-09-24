// /lib/features/calendar/widgets/preset_palette.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../../../core/models/preset.dart';

class PresetPalette extends StatelessWidget {
  final bool selectMode;

  const PresetPalette({super.key, this.selectMode = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          title: Text(selectMode ? 'Escolha o tipo de dia' : 'Tipos de dia'),
          content: SizedBox(
            width: double.maxFinite,
            child: provider.presets.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Nenhum tipo de dia cadastrado.'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: provider.presets.length,
                    itemBuilder: (context, index) {
                      final preset = provider.presets[index];
                      return ListTile(
                        leading: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(int.parse(preset.cor.replaceFirst('#', '0xFF'))),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(preset.nome),
                        subtitle: Text('${preset.duracao}h - ${preset.tipo}'),
                        onTap: selectMode
                            ? () => Navigator.of(context).pop(preset)
                            : null,
                        trailing: !selectMode && preset.id != null
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Excluir preset',
                                onPressed: () => _confirmDeletePreset(context, provider, preset),
                              )
                            : null,
                      );
                    },
                  ),
          ),
          actions: [
            if (!selectMode)
              TextButton(
                onPressed: () => _createPreset(context),
                child: const Text('Criar Novo'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _createPreset(BuildContext context) {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) => const _CreatePresetDialog(),
    );
  }

  void _confirmDeletePreset(BuildContext context, CalendarProvider provider, Preset preset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Preset'),
        content: Text('Tem certeza que deseja excluir o preset "${preset.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Fecha diálogo de confirmação
              try {
                await provider.deletePreset(preset.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preset excluído com sucesso!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir preset: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class _CreatePresetDialog extends StatefulWidget {
  const _CreatePresetDialog();

  @override
  State<_CreatePresetDialog> createState() => _CreatePresetDialogState();
}

class _CreatePresetDialogState extends State<_CreatePresetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _duracaoController;
  
  Color _selectedColor = Colors.blue;
  String _selectedTipo = 'normal';
  bool _flagAbatimento = false;
  bool _isSaving = false;

  // Cores predefinidas
  final List<Color> _predefinedColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.grey,
    Colors.red,
    Colors.yellow,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _duracaoController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _duracaoController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  Future<void> _savePreset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = Provider.of<CalendarProvider>(context, listen: false);
      
      final duracaoText = _duracaoController.text.trim().replaceAll(',', '.');
      final duracao = duracaoText.isEmpty 
          ? 0.0 
          : (double.tryParse(duracaoText) ?? 0.0);
      
      final preset = Preset(
        nome: _nomeController.text.trim(),
        cor: _colorToHex(_selectedColor),
        duracao: duracao,
        tipo: _selectedTipo,
        flagAbatimento: _flagAbatimento,
        visibilidade: 'private',
        intervals: [],
      );

      await provider.createPreset(preset);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preset criado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar preset: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header fixo
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Criar Novo Preset',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Conteúdo scrollável
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                // Nome
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Preset *',
                    border: OutlineInputBorder(),
                    helperText: 'Ex: 6h, 8h, 12x36, Folga',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Cor
                const Text('Cor *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _predefinedColors.map((color) {
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Duração
                TextFormField(
                  controller: _duracaoController,
                  decoration: const InputDecoration(
                    labelText: 'Duração (horas)',
                    border: OutlineInputBorder(),
                    helperText: 'Duração em horas (ex: 5.7, 6, 8, 12)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final num = double.tryParse(value.replaceAll(',', '.'));
                      if (num == null || num < 0) {
                        return 'Duração inválida';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Tipo
                DropdownButtonFormField<String>(
                  initialValue: _selectedTipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'plantao', child: Text('Plantão')),
                    DropdownMenuItem(value: 'folga', child: Text('Folga')),
                    DropdownMenuItem(value: 'abatimento', child: Text('Abatimento')),
                    DropdownMenuItem(value: 'atestado', child: Text('Atestado')),
                    DropdownMenuItem(value: 'ferias', child: Text('Férias')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTipo = value ?? 'normal';
                      if (_selectedTipo == 'abatimento' || _selectedTipo == 'atestado') {
                        _flagAbatimento = true;
                      } else {
                        _flagAbatimento = false;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Flag Abatimento
                CheckboxListTile(
                  title: const Text('Flag Abatimento'),
                  subtitle: const Text('Marca como abatimento de horas'),
                  value: _flagAbatimento,
                  onChanged: (value) {
                    setState(() {
                      _flagAbatimento = value ?? false;
                    });
                  },
                ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer fixo com botões
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _savePreset,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Criar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

