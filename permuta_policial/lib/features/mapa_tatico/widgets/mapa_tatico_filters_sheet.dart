import 'package:flutter/material.dart';

import '../models/mapa_tatico_filters.dart';
import '../utils/mapa_tatico_marker_utils.dart';

class MapaTaticoFiltersSheet extends StatefulWidget {
  final String mapType;
  final MapaTaticoFilters initialFilters;

  const MapaTaticoFiltersSheet({
    super.key,
    required this.mapType,
    required this.initialFilters,
  });

  @override
  State<MapaTaticoFiltersSheet> createState() => _MapaTaticoFiltersSheetState();
}

class _MapaTaticoFiltersSheetState extends State<MapaTaticoFiltersSheet> {
  late Set<String> _types;
  late bool _onlyMine;
  double? _maxDistance;
  int? _expiringHours;

  @override
  void initState() {
    super.initState();
    _types = Set<String>.from(widget.initialFilters.types);
    _onlyMine = widget.initialFilters.onlyMine;
    _maxDistance = widget.initialFilters.maxDistanceMeters;
    _expiringHours = widget.initialFilters.expiringWithinHours;
  }

  Set<String> get _availableTypes => MapaTaticoFilters.typesForMapTab(widget.mapType);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filtros — ${widget.mapType == 'LOGISTICS' ? 'Logística' : widget.mapType == 'NATIONAL' ? 'Nacional' : 'Operacional'}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text('Tipos', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: _availableTypes.map((type) {
                  final selected = _types.contains(type);
                  return FilterChip(
                    label: Text(pointTypeLabel(type)),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _types.add(type);
                        } else {
                          _types.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Só meus pontos'),
                value: _onlyMine,
                onChanged: (v) => setState(() => _onlyMine = v),
              ),
              const Text('Distância máxima', style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _maxDistance ?? 5000,
                min: 500,
                max: 10000,
                divisions: 19,
                label: _maxDistance == null ? 'Sem limite' : '${(_maxDistance!).toInt()} m',
                onChanged: (v) => setState(() => _maxDistance = v),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _maxDistance = null),
                  child: const Text('Sem limite de distância'),
                ),
              ),
              if (widget.mapType == 'OPERATIONAL') ...[
                const Text('Expirando em', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Qualquer'),
                      selected: _expiringHours == null,
                      onSelected: (_) => setState(() => _expiringHours = null),
                    ),
                    ChoiceChip(
                      label: const Text('24 h'),
                      selected: _expiringHours == 24,
                      onSelected: (_) => setState(() => _expiringHours = 24),
                    ),
                    ChoiceChip(
                      label: const Text('6 h'),
                      selected: _expiringHours == 6,
                      onSelected: (_) => setState(() => _expiringHours = 6),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, const MapaTaticoFilters()),
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        MapaTaticoFilters(
                          types: _types,
                          onlyMine: _onlyMine,
                          maxDistanceMeters: _maxDistance,
                          expiringWithinHours: _expiringHours,
                        ),
                      ),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
