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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.globalGroup != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.public),
              title: const Text('Mapa Nacional Colaborativo'),
              subtitle: const Text('Acesse pela aba "Nacional" no mapa.'),
            ),
          ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: active?.id,
          decoration: const InputDecoration(
            labelText: 'Grupo ativo',
            border: OutlineInputBorder(),
          ),
          items: provider.privateGroups
              .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
              .toList(),
          onChanged: (id) {
            if (id != null) onSwitchGroup(id);
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onShowInvites,
              icon: const Icon(Icons.mail_outline),
              label: Text('Convites (${provider.pendingInvites.length})'),
            ),
            if (active != null)
              OutlinedButton.icon(
                onPressed: onShowMembers,
                icon: const Icon(Icons.people),
                label: Text(canManageGroup ? 'Gerenciar membros' : 'Ver membros'),
              ),
            if (active != null && canManageGroup)
              OutlinedButton.icon(
                onPressed: onInvite,
                icon: const Icon(Icons.person_add),
                label: const Text('Convidar'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Seus grupos', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...provider.groups.map((g) => _GroupTile(
              group: g,
              isActive: g.id == active?.id,
              onTap: () => onSwitchGroup(g.id),
              onLeave: () => onLeaveGroup(g.id, g.name),
            )),
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
