import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mapa_tatico_provider.dart';

class MapaTaticoIntelligenceScreen extends StatefulWidget {
  const MapaTaticoIntelligenceScreen({super.key});

  @override
  State<MapaTaticoIntelligenceScreen> createState() => _MapaTaticoIntelligenceScreenState();
}

class _MapaTaticoIntelligenceScreenState extends State<MapaTaticoIntelligenceScreen> {
  String _mapType = 'OPERATIONAL';
  Map<String, dynamic>? _data;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final provider = context.read<MapaTaticoProvider>();
    final data = await provider.getIntelligence(_mapType);
    if (mounted) {
      setState(() {
        _data = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupName = context.watch<MapaTaticoProvider>().activeGroup?.name ?? 'Grupo';

    return Scaffold(
      appBar: AppBar(title: Text('Inteligência — $groupName')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'OPERATIONAL', label: Text('Operacional')),
                ButtonSegment(value: 'LOGISTICS', label: Text('Logística')),
              ],
              selected: {_mapType},
              onSelectionChanged: (s) {
                setState(() => _mapType = s.first);
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _data == null
                    ? const Center(child: Text('Sem dados para exibir.'))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const Text('Por tipo', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...((_data!['points_by_type'] as List?) ?? []).map(
                            (row) => ListTile(
                              dense: true,
                              title: Text('${row['type']}'),
                              trailing: Text('${row['total']}'),
                            ),
                          ),
                          const Divider(height: 24),
                          const Text('Mais comentados', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...((_data!['top_commented'] as List?) ?? []).map(
                            (row) => ListTile(
                              dense: true,
                              title: Text(row['title']?.toString() ?? ''),
                              subtitle: Text('${row['comments_count']} comentários'),
                            ),
                          ),
                          if (_mapType == 'LOGISTICS') ...[
                            const Divider(height: 24),
                            const Text('Mais visitados (7 dias)', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...((_data!['top_visited'] as List?) ?? []).map(
                              (row) => ListTile(
                                dense: true,
                                title: Text(row['title']?.toString() ?? ''),
                                subtitle: Text('${row['visits_count']} visitas'),
                              ),
                            ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
