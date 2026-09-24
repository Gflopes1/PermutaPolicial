import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/repositories/mapa_tatico_admin_repository.dart';
import '../../../core/config/app_styles.dart';

class MapaTaticoAdminGroupDetailScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  const MapaTaticoAdminGroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<MapaTaticoAdminGroupDetailScreen> createState() =>
      _MapaTaticoAdminGroupDetailScreenState();
}

class _MapaTaticoAdminGroupDetailScreenState extends State<MapaTaticoAdminGroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MapaTaticoAdminRepository _adminRepo;
  Map<String, dynamic>? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _adminRepo = MapaTaticoAdminRepository(context.read<ApiClient>());
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _detail = await _adminRepo.getGroupDetail(widget.groupId);
    } catch (_) {
      _detail = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _confirmDeletePoint(int pointId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover ponto'),
        content: const Text('Confirma a remoção deste ponto?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover')),
        ],
      ),
    );
    if (ok != true) return;
    await _adminRepo.removePoint(widget.groupId, pointId);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(AppStyles.successSnackBar('Ponto removido.'));
    }
  }

  Future<void> _confirmDeleteMember(int userId, String nome) async {
    final motivoController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remover $nome'),
        content: TextField(
          controller: motivoController,
          decoration: const InputDecoration(
            labelText: 'Motivo (obrigatório)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover')),
        ],
      ),
    );
    final motivo = motivoController.text.trim();
    motivoController.dispose();
    if (ok != true || motivo.length < 10) {
      if (mounted && ok == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.errorSnackBar('Informe um motivo com pelo menos 10 caracteres.'),
        );
      }
      return;
    }
    await _adminRepo.removeMember(widget.groupId, userId, motivo);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(AppStyles.successSnackBar('Membro removido.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Membros'), Tab(text: 'Pontos')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
              ? const Center(child: Text('Grupo não encontrado.'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMembers(),
                    _buildPoints(),
                  ],
                ),
    );
  }

  Widget _buildMembers() {
    final members = (_detail!['members'] as List<dynamic>? ?? []);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final m = members[index] as Map<String, dynamic>;
        final nome = m['nome_de_guerra']?.toString() ?? m['nome']?.toString() ?? 'Membro';
        return ListTile(
          title: Text(nome),
          subtitle: Text(
            '${m['role']} • ${m['is_muted'] == true || m['is_muted'] == 1 ? 'Mutado' : 'Ativo'}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.person_remove, color: Colors.red),
            onPressed: () => _confirmDeleteMember(m['user_id'] as int, nome),
          ),
        );
      },
    );
  }

  Widget _buildPoints() {
    final points = (_detail!['points'] as List<dynamic>? ?? []);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: points.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final p = points[index] as Map<String, dynamic>;
        final isPrivate = p['visibility'] == 'PRIVATE';
        return ListTile(
          leading: Icon(isPrivate ? Icons.lock : Icons.place),
          title: Text(
            isPrivate ? 'Conteúdo oculto (ponto privado)' : (p['title']?.toString() ?? 'Ponto'),
          ),
          subtitle: Text('${p['type']} • ${p['map_type']}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDeletePoint(p['id'] as int),
          ),
        );
      },
    );
  }
}
