// /lib/features/calendar/widgets/day_modal.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../../../core/models/work_day.dart';
import '../../../core/models/preset.dart';
import '../../../core/utils/error_handler.dart';
import 'preset_palette.dart';

class DayModal extends StatefulWidget {
  final DateTime day;

  const DayModal({super.key, required this.day});

  @override
  State<DayModal> createState() => _DayModalState();
}

class _DayModalState extends State<DayModal> {
  late WorkDay _workDay;
  bool _isEditing = false;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    try {
      _syncFromProvider();
    } catch (e) {
      debugPrint('❌ Erro ao inicializar DayModal: $e');
      _workDay = WorkDay(data: WorkDay.toDateOnly(widget.day), tipo: 'normal');
    }
  }

  void _syncFromProvider() {
    try {
      final provider = Provider.of<CalendarProvider>(context, listen: false);
      final dayOnly = WorkDay.toDateOnly(widget.day);
      final existing = provider.getWorkDay(dayOnly);
      _workDay = existing != null
          ? WorkDay(
              id: existing.id,
              data: dayOnly,
              presetId: existing.presetId,
              presetNome: existing.presetNome,
              presetCor: existing.presetCor,
              presetTipo: existing.presetTipo,
              totalHours: existing.totalHours,
              etapas: existing.etapas,
              tipo: existing.tipo,
              flagAbatimento: existing.flagAbatimento,
              observacoes: existing.observacoes,
              intervals: existing.intervals,
            )
          : WorkDay(data: dayOnly, tipo: 'normal');
    } catch (e) {
      debugPrint('❌ Erro ao sincronizar WorkDay do provider: $e');
      final dayOnly = WorkDay.toDateOnly(widget.day);
      _workDay = WorkDay(data: dayOnly, tipo: 'normal');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(widget.day),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            _workDay.presetNome ?? 'Sem tipo definido',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (_workDay.presetCor != null)
                      Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _parseColor(_workDay.presetCor!),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                      ),
                    IconButton(
                      icon: Icon(_isEditing ? Icons.check : Icons.edit_outlined),
                      tooltip: _isEditing ? 'Concluir edição' : 'Editar manualmente',
                      onPressed: _isApplying
                          ? null
                          : () {
                              setState(() => _isEditing = !_isEditing);
                              if (!_isEditing) _saveDay();
                            },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: _isEditing ? _buildEditView() : _buildViewView(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewView() {
    return Consumer<CalendarProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aplicar tipo de dia',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (provider.presets.isEmpty)
              const Text('Nenhum tipo cadastrado. Crie em "Tipos" na barra inferior.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.presets.map((preset) {
                  final isActive = _workDay.presetId == preset.id;
                  return FilterChip(
                    selected: isActive,
                    avatar: CircleAvatar(
                      backgroundColor: _parseColor(preset.cor),
                      radius: 10,
                    ),
                    label: Text('${preset.nome} (${preset.duracao}h)'),
                    onSelected: _isApplying
                        ? null
                        : (_) => _applyPreset(preset),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _isApplying ? null : () => _pickPresetFromDialog(),
                icon: const Icon(Icons.list),
                label: const Text('Ver todos os tipos'),
              ),
            ),
            if (_isApplying) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Aplicando tipo de dia...'),
            ],
            const Divider(height: 32),
            _buildInfoRow('Tipo', _workDay.tipo),
            _buildInfoRow('Horas', '${_workDay.totalHours.toStringAsFixed(2)}h'),
            _buildInfoRow('Etapas', '${_workDay.etapas}'),
            if (_workDay.observacoes != null && _workDay.observacoes!.isNotEmpty)
              _buildInfoRow('Observações', _workDay.observacoes!),
            const SizedBox(height: 16),
            if (_workDay.id != null || _workDay.presetId != null || _workDay.totalHours > 0)
              OutlinedButton.icon(
                onPressed: _isApplying ? null : _clearDay,
                icon: const Icon(Icons.clear, color: Colors.red),
                label: const Text('Limpar este dia'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEditView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _workDay.tipo,
          decoration: const InputDecoration(
            labelText: 'Tipo',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'normal', child: Text('Normal')),
            DropdownMenuItem(value: 'plantao', child: Text('Plantão')),
            DropdownMenuItem(value: 'folga', child: Text('Folga')),
            DropdownMenuItem(value: 'atestado', child: Text('Atestado')),
            DropdownMenuItem(value: 'abatimento', child: Text('Abatimento')),
            DropdownMenuItem(value: 'ferias', child: Text('Férias')),
          ],
          onChanged: (value) {
            final newValue = value ?? 'normal';
            setState(() => _workDay = _updateWorkDay(tipo: newValue));
            Provider.of<CalendarProvider>(context, listen: false).upsertDay(_workDay);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _workDay.totalHours.toString(),
          decoration: const InputDecoration(
            labelText: 'Horas',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final hours = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
            setState(() => _workDay = _updateWorkDay(totalHours: hours));
            Provider.of<CalendarProvider>(context, listen: false).upsertDay(_workDay);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _workDay.observacoes ?? '',
          decoration: const InputDecoration(
            labelText: 'Observações',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) {
            setState(
              () => _workDay = _updateWorkDay(
                observacoes: value.isEmpty ? null : value,
              ),
            );
            Provider.of<CalendarProvider>(context, listen: false).upsertDay(_workDay);
          },
        ),
      ],
    );
  }

  WorkDay _updateWorkDay({String? tipo, double? totalHours, String? observacoes}) {
    final dayOnly = WorkDay.toDateOnly(widget.day);
    return WorkDay(
      id: _workDay.id,
      data: dayOnly,
      presetId: _workDay.presetId,
      presetNome: _workDay.presetNome,
      presetCor: _workDay.presetCor,
      presetTipo: _workDay.presetTipo,
      tipo: tipo ?? _workDay.tipo,
      totalHours: totalHours ?? _workDay.totalHours,
      etapas: _workDay.etapas,
      flagAbatimento: _workDay.flagAbatimento,
      observacoes: observacoes ?? _workDay.observacoes,
      intervals: _workDay.intervals,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    const months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
    ];
    final weekday = weekdays[date.weekday - 1];
    return '$weekday, ${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }

  void _saveDay() {
    Provider.of<CalendarProvider>(context, listen: false).upsertDay(_workDay);
  }

  Future<void> _pickPresetFromDialog() async {
    final preset = await showDialog<Preset>(
      context: context,
      builder: (context) => const PresetPalette(selectMode: true),
    );
    if (preset != null) await _applyPreset(preset);
  }

  Future<void> _applyPreset(Preset preset) async {
    if (preset.id == null) {
      _showMessage('Tipo de dia inválido. Tente recarregar a tela.');
      return;
    }

    setState(() => _isApplying = true);

    try {
      final provider = Provider.of<CalendarProvider>(context, listen: false);
      await provider.applyPresetToDay(WorkDay.toDateOnly(widget.day), preset.id!);
      if (!mounted) return;
      _syncFromProvider();
      setState(() {});
      _showMessage('${preset.nome} aplicado com sucesso!');
    } catch (e) {
      if (mounted) {
        _showMessage(ErrorHandler.getErrorMessage(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  Future<void> _clearDay() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar dia'),
        content: const Text('Remover marcação e horas deste dia?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final provider = Provider.of<CalendarProvider>(context, listen: false);
    await provider.deleteDay(widget.day);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }
}
