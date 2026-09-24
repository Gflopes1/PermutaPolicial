import 'package:flutter/material.dart';

import '../models/map_group.dart';
import '../providers/mapa_tatico_provider.dart';

class MapaTaticoGroupPanel extends StatelessWidget {
  final MapaTaticoProvider provider;
  final bool canManageGroup;
  final VoidCallback onCreateGroup;
  final void Function(int groupId) onSwitchGroup;
  final void Function(int groupId, String name) onLeaveGroup;
  final VoidCallback onShowInvites;
  final VoidCallback onShowMembers;
  final VoidCallback onInvite;

  const MapaTaticoGroupPanel({
    super.key,
    required this.provider,
    required this.canManageGroup,
    required this.onCreateGroup,
    required this.onSwitchGroup,
    required this.onLeaveGroup,
    required this.onShowInvites,
    required this.onShowMembers,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.privateGroups.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (provider.globalGroup != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.public, color: Colors.lightBlueAccent),
                title: const Text('Mapa Nacional Colaborativo'),
                subtitle: const Text(
                  'Você já participa do mapa nacional, visível para todos os usuários.',
                ),
              ),
            ),
          const SizedBox(height: 32),
          const Icon(Icons.group_add, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Você ainda não participa de nenhum grupo fechado.\n'
            'Grupos fechados liberam os mapas Operacional e Logístico da sua equipe.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: onCreateGroup,
              icon: const Icon(Icons.add),
              label: const Text('Criar Grupo'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: onShowInvites,
              icon: const Icon(Icons.mail_outline),
              label: Text('Ver convites (${provider.pendingInvites.length})'),
            ),
          ),
        ],
      );
    }

    final active = provider.activeGroup;
    final hasActivePrivateGroup = active != null && !active.isGlobal;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ActionGrid(
          inviteCount: provider.pendingInvites.length,
          canManageGroup: canManageGroup,
          hasActiveGroup: hasActivePrivateGroup,
          onShowInvites: onShowInvites,
          onCreateGroup: onCreateGroup,
          onShowMembers: onShowMembers,
          onInvite: onInvite,
        ),
        const SizedBox(height: 16),
        const Text('Seus grupos', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...provider.privateGroups.map((g) => _GroupTile(
              group: g,
              isActive: g.id == active?.id,
              onTap: () => onSwitchGroup(g.id),
              onLeave: () => onLeaveGroup(g.id, g.name),
            )),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final int inviteCount;
  final bool canManageGroup;
  final bool hasActiveGroup;
  final VoidCallback onShowInvites;
  final VoidCallback onCreateGroup;
  final VoidCallback onShowMembers;
  final VoidCallback onInvite;

  const _ActionGrid({
    required this.inviteCount,
    required this.canManageGroup,
    required this.hasActiveGroup,
    required this.onShowInvites,
    required this.onCreateGroup,
    required this.onShowMembers,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onShowInvites,
                icon: const Icon(Icons.mail_outline, size: 18),
                label: Text('Convites ($inviteCount)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCreateGroup,
                icon: const Icon(Icons.group_add, size: 18),
                label: const Text('Novo grupo'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: hasActiveGroup ? onShowMembers : null,
                icon: const Icon(Icons.people, size: 18),
                label: Text(canManageGroup ? 'Gerenciar membros' : 'Ver membros'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: hasActiveGroup && canManageGroup ? onInvite : null,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Convidar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupTile extends StatelessWidget {
  final MapGroup group;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLeave;

  const _GroupTile({
    required this.group,
    required this.isActive,
    required this.onTap,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isActive ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35) : null,
      child: ListTile(
        leading: Icon(isActive ? Icons.check_circle : Icons.group),
        title: Text(group.name),
        subtitle: Text(isActive ? 'Grupo ativo' : 'Toque para ativar'),
        onTap: onTap,
        trailing: TextButton(onPressed: onLeave, child: const Text('Sair')),
      ),
    );
  }
}
