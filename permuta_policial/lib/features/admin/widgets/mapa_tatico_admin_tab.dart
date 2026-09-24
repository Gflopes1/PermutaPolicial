import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/repositories/mapa_tatico_admin_repository.dart';
import '../../../core/api/repositories/mapa_tatico_repository.dart';
import '../screens/mapa_tatico_admin_group_detail_screen.dart';

class MapaTaticoAdminTab extends StatefulWidget {
  const MapaTaticoAdminTab({super.key});

  @override
  State<MapaTaticoAdminTab> createState() => _MapaTaticoAdminTabState();
}

class _MapaTaticoAdminTabState extends State<MapaTaticoAdminTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MapaTaticoAdminRepository _adminRepo;

  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _groups = [];
  bool _loadingReports = true;
  bool _loadingGroups = true;
  int _groupsPage = 1;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _adminRepo = MapaTaticoAdminRepository(context.read<ApiClient>());
    _loadReports();
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _loadingReports = true);
    try {
      final repo = context.read<MapaTaticoRepository>();
      _reports = await repo.listReports();
    } catch (_) {
      _reports = [];
    }
    if (mounted) setState(() => _loadingReports = false);
  }

  Future<void> _loadGroups({bool reset = false}) async {
    if (reset) _groupsPage = 1;
    setState(() => _loadingGroups = true);
    try {
      final data = await _adminRepo.listGroups(
        page: _groupsPage,
        search: _searchController.text.trim(),
      );
      final items = (data['groups'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      setState(() {
        _groups = reset ? items : [..._groups, ...items];
      });
    } catch (_) {
      if (reset) _groups = [];
    }
    if (mounted) setState(() => _loadingGroups = false);
  }

  Future<void> _review(int reportId, String status) async {
    final repo = context.read<MapaTaticoRepository>();
    await repo.reviewReport(reportId, status);
    await _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Denúncias'),
            Tab(text: 'Grupos'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildReportsTab(),
              _buildGroupsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTab() {
    if (_loadingReports) return const Center(child: CircularProgressIndicator());
    if (_reports.isEmpty) {
      return const Center(child: Text('Nenhuma denúncia pendente no mapa tático.'));
    }
    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final r = _reports[index];
          return ListTile(
            title: Text(r['point_title']?.toString() ?? 'Ponto #${r['point_id']}'),
            subtitle: Text(
              '${r['group_name']} • ${r['reporter_nome'] ?? 'Anônimo'}\n${r['reason'] ?? ''}',
            ),
            isThreeLine: true,
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  tooltip: 'Revisado',
                  onPressed: () => _review(r['id'] as int, 'REVIEWED'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  tooltip: 'Arquivar',
                  onPressed: () => _review(r['id'] as int, 'DISMISSED'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar grupo',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _loadGroups(reset: true),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _loadGroups(reset: true),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingGroups && _groups.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => _loadGroups(reset: true),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _groups.length + 1,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == _groups.length) {
                        return TextButton(
                          onPressed: _loadingGroups
                              ? null
                              : () {
                                  _groupsPage += 1;
                                  _loadGroups();
                                },
                          child: const Text('Carregar mais'),
                        );
                      }
                      final g = _groups[index];
                      return ListTile(
                        leading: const Icon(Icons.groups),
                        title: Text(g['name']?.toString() ?? 'Grupo'),
                        subtitle: Text(
                          '${g['member_count'] ?? 0} membros • ${g['point_count'] ?? 0} pontos\n'
                          'Criador: ${g['creator_nome'] ?? '-'}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MapaTaticoAdminGroupDetailScreen(
                                groupId: g['id'] as int,
                                groupName: g['name']?.toString() ?? 'Grupo',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
