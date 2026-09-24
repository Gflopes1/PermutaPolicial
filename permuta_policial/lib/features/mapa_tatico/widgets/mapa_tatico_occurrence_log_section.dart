import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_styles.dart';
import '../models/map_occurrence_log_entry.dart';
import '../providers/mapa_tatico_provider.dart';

class MapaTaticoOccurrenceLogSection extends StatefulWidget {
  final int pointId;
  final bool canAdd;

  const MapaTaticoOccurrenceLogSection({
    super.key,
    required this.pointId,
    required this.canAdd,
  });

  @override
  State<MapaTaticoOccurrenceLogSection> createState() => _MapaTaticoOccurrenceLogSectionState();
}

class _MapaTaticoOccurrenceLogSectionState extends State<MapaTaticoOccurrenceLogSection> {
  List<MapOccurrenceLogEntry> _entries = [];
  bool _loading = true;
  bool _saving = false;
  final _narrativeController = TextEditingController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _narrativeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final provider = context.read<MapaTaticoProvider>();
    final entries = await provider.getOccurrenceLog(widget.pointId);
    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final text = _narrativeController.text.trim();
    if (text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar('A narrativa deve ter pelo menos 5 caracteres.'),
      );
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<MapaTaticoProvider>();
    final entry = await provider.addOccurrenceLogEntry(
      widget.pointId,
      narrative: text,
      status: _selectedStatus,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (entry != null) {
      _narrativeController.clear();
      _selectedStatus = null;
      setState(() => _entries.insert(0, entry));
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.successSnackBar('Entrada registrada.'),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar(provider.errorMessage ?? 'Erro ao registrar entrada.'),
      );
    }
  }

  String _entryTypeLabel(String type) {
    switch (type) {
      case 'MUDANCA_STATUS':
        return 'Mudança de status';
      case 'EVIDENCIA':
        return 'Evidência';
      case 'OBSERVACAO':
        return 'Observação';
      default:
        return 'Atualização';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Histórico da ocorrência',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(strokeWidth: 2),
          ))
        else if (_entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Nenhuma entrada registrada ainda.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          ..._entries.map(
            (e) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(
                          label: Text(_entryTypeLabel(e.entryType), style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ),
                        if (e.status != null) ...[
                          const SizedBox(width: 6),
                          Chip(
                            label: Text(e.status!, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(e.narrative),
                    const SizedBox(height: 6),
                    Text(
                      '${e.authorDisplayName ?? 'Membro'} • '
                      '${DateFormat('dd/MM/yyyy HH:mm').format(e.occurredAt)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (widget.canAdd) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _narrativeController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Nova entrada',
              hintText: 'Descreva a atualização da ocorrência...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status (opcional)',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'EM_ANDAMENTO', child: Text('Em andamento')),
              DropdownMenuItem(value: 'CONCLUIDA', child: Text('Concluída')),
              DropdownMenuItem(value: 'ARQUIVADA', child: Text('Arquivada')),
            ],
            onChanged: (v) => setState(() => _selectedStatus = v),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('Adicionar entrada'),
            ),
          ),
        ],
      ],
    );
  }
}
