import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_styles.dart';
import '../../../shared/widgets/app_bar_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/group_invite.dart';
import '../models/map_group_member.dart';
import '../models/map_point.dart';
import '../providers/mapa_tatico_provider.dart';
import '../widgets/criar_ponto_map_modal.dart';

class MapaTaticoScreen extends StatefulWidget {
  const MapaTaticoScreen({super.key});

  @override
  State<MapaTaticoScreen> createState() => _MapaTaticoScreenState();
}

class _MapaTaticoScreenState extends State<MapaTaticoScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late TabController _tabController;
  bool _showToolbarActions = false;
  int _toolbarMenuTab = 0;
  bool _soundAlertEnabled = true;
  bool _navigationModeEnabled = false;
  LatLng? _lastCenteredPosition;
  Timer? _navigationRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MapaTaticoProvider>();
      provider.loadGroups();
      provider.setAppInForeground(true);
      provider.onProximityAlert = _showProximityAlert;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<MapaTaticoProvider>();
    provider.setAppInForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    _navigationRefreshTimer?.cancel();
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    context.read<MapaTaticoProvider>().setAppInForeground(false);
    super.dispose();
  }

  void _showProximityAlert() {
    if (!mounted) return;
    if (_soundAlertEnabled) {
      SystemSound.play(SystemSoundType.alert);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Você está próximo de um ponto no mapa!'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    final provider = context.read<MapaTaticoProvider>();
    var pos = provider.currentPosition;

    if (pos == null) {
      final ok = await provider.requestAndRefreshCurrentLocation();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.errorSnackBar(
            'Não foi possível obter sua localização. No navegador, permita localização para este site e use HTTPS.',
          ),
        );
        return;
      }
      pos = provider.currentPosition;
    }

    if (pos != null) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
    }
  }

  void _toggleNavigationMode() {
    setState(() {
      _navigationModeEnabled = !_navigationModeEnabled;
    });
    if (_navigationModeEnabled) {
      _goToMyLocation();
      _navigationRefreshTimer?.cancel();
      _navigationRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        if (!mounted || !_navigationModeEnabled) return;
        final provider = context.read<MapaTaticoProvider>();
        await provider.requestAndRefreshCurrentLocation();
      });
    } else {
      _navigationRefreshTimer?.cancel();
      _navigationRefreshTimer = null;
    }
  }

  void _toggleSoundAlert() {
    setState(() {
      _soundAlertEnabled = !_soundAlertEnabled;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      AppStyles.successSnackBar(
        _soundAlertEnabled ? 'Aviso sonoro ativado.' : 'Aviso sonoro desativado.',
      ),
    );
  }

  bool _canManageGroup(MapaTaticoProvider provider) {
    final user = context.read<AuthProvider>().user;
    return provider.activeGroup?.isModerator == true ||
        user?.isModerator == true ||
        user?.isEmbaixador == true;
  }

  bool _canEditNomeDeGuerra(MapaTaticoProvider provider, MapGroupMember member) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    if (currentUserId == null) return false;
    return currentUserId == member.userId || _canManageGroup(provider);
  }

  Future<void> _showNomeDeGuerraDialog(
    MapaTaticoProvider provider,
    MapGroupMember member,
    Future<void> Function() refreshMembers,
  ) async {
    final controller = TextEditingController(text: member.nomeDeGuerra ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Nome de guerra de ${member.nome}'),
        content: TextField(
          controller: controller,
          maxLength: 100,
          decoration: const InputDecoration(
            labelText: 'Nome de guerra',
            hintText: 'Deixe vazio para remover',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    try {
      await provider.updateMemberNomeDeGuerra(member.userId, controller.text.trim());
      await refreshMembers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.successSnackBar('Nome de guerra atualizado com sucesso.'),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar(
          provider.errorMessage ?? 'Não foi possível atualizar o nome de guerra.',
        ),
      );
    }
  }

  void _openCriarPonto() {
    final provider = context.read<MapaTaticoProvider>();
    if (provider.activeGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar('Selecione ou crie um grupo primeiro.'),
      );
      return;
    }
    if (provider.isMuted) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar('Você está mutado e não pode criar pontos.'),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => CriarPontoMapModal(
        groupId: provider.activeGroup!.id,
        onCreated: () => provider.loadPoints(),
      ),
    );
  }

  void _showAlertRadiusSettings() {
    final provider = context.read<MapaTaticoProvider>();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          double radius = provider.alertRadiusMeters;
          return AlertDialog(
            title: const Text('Raio de Alerta'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${radius.toInt()} metros'),
                Slider(
                  value: radius,
                  min: 50,
                  max: 1000,
                  divisions: 19,
                  label: '${radius.toInt()}m',
                  onChanged: (v) {
                    setState(() => radius = v);
                    provider.setAlertRadius(v);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showPendingInvitesDialog(MapaTaticoProvider provider) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer<MapaTaticoProvider>(
          builder: (context, liveProvider, _) {
            final invites = liveProvider.pendingInvites;
            return AlertDialog(
              title: const Text('Convites pendentes'),
              content: SizedBox(
                width: 460,
                child: invites.isEmpty
                    ? const Text('Você não tem convites pendentes no mapa tático.')
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: invites.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final invite = invites[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(invite.groupName ?? 'Grupo #${invite.groupId}'),
                            subtitle: Text(invite.email),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: () => _rejectInvite(liveProvider, invite),
                                  child: const Text('Recusar'),
                                ),
                                ElevatedButton(
                                  onPressed: () => _acceptInvite(liveProvider, invite),
                                  child: const Text('Aceitar'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Fechar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _acceptInvite(MapaTaticoProvider provider, GroupInvite invite) async {
    try {
      await provider.acceptInvite(invite.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.successSnackBar('Convite aceito com sucesso!'),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar(provider.errorMessage ?? 'Não foi possível aceitar o convite.'),
      );
    }
  }

  Future<void> _rejectInvite(MapaTaticoProvider provider, GroupInvite invite) async {
    try {
      await provider.rejectInvite(invite.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.successSnackBar('Convite recusado.'),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar(provider.errorMessage ?? 'Não foi possível recusar o convite.'),
      );
    }
  }

  void _showInviteDialog(MapaTaticoProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar usuário ao grupo'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'E-mail do usuário',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = controller.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await provider.inviteToGroup(email);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  AppStyles.successSnackBar('Convite enviado com sucesso!'),
                );
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  AppStyles.errorSnackBar(provider.errorMessage ?? 'Erro ao enviar convite.'),
                );
              }
            },
            child: const Text('Enviar convite'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeaveGroup(MapaTaticoProvider provider, int groupId, String groupName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do grupo'),
        content: Text('Deseja sair de "$groupName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sair')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await provider.leaveGroup(groupId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.successSnackBar('Você saiu do grupo.'),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar(provider.errorMessage ?? 'Não foi possível sair do grupo.'),
      );
    }
  }

  Future<void> _showEditPointDialog(MapaTaticoProvider provider, MapPoint point) async {
    final titleController = TextEditingController(text: point.title);
    final addressController = TextEditingController(text: point.address ?? '');
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar marcador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Endereço'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
        ],
      ),
    );
    if (save != true) return;
    final success = await provider.updatePoint(point.id, {
      'title': titleController.text.trim(),
      'address': addressController.text.trim(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      success
          ? AppStyles.successSnackBar('Marcador atualizado.')
          : AppStyles.errorSnackBar(provider.errorMessage ?? 'Não foi possível atualizar o marcador.'),
    );
  }

  Future<void> _showMembersSheet(MapaTaticoProvider provider) async {
    if (provider.activeGroup == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            late Future<List<MapGroupMember>> membersFuture;
            membersFuture = provider.getGroupMembers();

            Future<void> refreshMembers() async {
              setSheetState(() {
                membersFuture = provider.getGroupMembers();
              });
            }

            return FractionallySizedBox(
              heightFactor: 0.82,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Membros de ${provider.activeGroup!.name}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_canManageGroup(provider))
                          ElevatedButton.icon(
                            onPressed: () => _showInviteDialog(provider),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Convidar'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: FutureBuilder<List<MapGroupMember>>(
                        future: membersFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final members = snapshot.data ?? [];
                          if (members.isEmpty) {
                            return const Center(
                              child: Text('Nenhum membro encontrado para este grupo.'),
                            );
                          }
                          return ListView.separated(
                            itemCount: members.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final member = members[index];
                              final canManage = _canManageGroup(provider);
                              final canEditNome = _canEditNomeDeGuerra(provider, member);
                              final canMuteOrRemove = canManage && !member.isModerator;
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    member.displayName.isNotEmpty
                                        ? member.displayName.substring(0, 1).toUpperCase()
                                        : '?',
                                  ),
                                ),
                                title: Text(member.displayName),
                                subtitle: Text(
                                  [
                                    member.nome,
                                    member.email,
                                    member.isModerator ? 'Moderador do grupo' : 'Membro do grupo',
                                    if (member.isMuted) 'Mutado',
                                  ].whereType<String>().where((e) => e.trim().isNotEmpty).join(' • '),
                                ),
                                trailing: (canEditNome || canMuteOrRemove)
                                    ? PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          if (value == 'nome_de_guerra') {
                                            await _showNomeDeGuerraDialog(
                                              provider,
                                              member,
                                              refreshMembers,
                                            );
                                          }
                                          if (value == 'mute' || value == 'unmute') {
                                            try {
                                              await provider.muteMember(member.userId, value == 'mute');
                                              await refreshMembers();
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                AppStyles.successSnackBar(
                                                  value == 'mute'
                                                      ? 'Usuário mutado.'
                                                      : 'Usuário desmutado.',
                                                ),
                                              );
                                            } catch (_) {
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                AppStyles.errorSnackBar(
                                                  provider.errorMessage ?? 'Não foi possível atualizar o membro.',
                                                ),
                                              );
                                            }
                                          }
                                          if (value == 'remove') {
                                            try {
                                              await provider.removeMember(member.userId);
                                              await refreshMembers();
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                AppStyles.successSnackBar('Usuário removido do grupo.'),
                                              );
                                            } catch (_) {
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                AppStyles.errorSnackBar(
                                                  provider.errorMessage ?? 'Não foi possível remover o usuário.',
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        itemBuilder: (_) {
                                          final items = <PopupMenuEntry<String>>[];
                                          if (canEditNome) {
                                            items.add(
                                              const PopupMenuItem(
                                                value: 'nome_de_guerra',
                                                child: Text('Editar nome de guerra'),
                                              ),
                                            );
                                          }
                                          if (canMuteOrRemove) {
                                            items.add(
                                              PopupMenuItem(
                                                value: member.isMuted ? 'unmute' : 'mute',
                                                child: Text(member.isMuted ? 'Desmutar' : 'Mutar'),
                                              ),
                                            );
                                            items.add(
                                              const PopupMenuItem(
                                                value: 'remove',
                                                child: Text('Remover do grupo'),
                                              ),
                                            );
                                          }
                                          return items;
                                        },
                                      )
                                    : null,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapaTaticoProvider>(
      builder: (context, provider, _) {
        final canManageGroup = _canManageGroup(provider);
        final isMobile = MediaQuery.of(context).size.width < 700;
        final appBarBottomHeight = isMobile
            ? (_showToolbarActions ? 340.0 : 58.0)
            : (_showToolbarActions ? 300.0 : 58.0);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mapa Tático e Logístico'),
            actions: [
              IconButton(
                icon: Icon(_showToolbarActions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                tooltip: _showToolbarActions ? 'Ocultar opções' : 'Mostrar opções',
                onPressed: () => setState(() => _showToolbarActions = !_showToolbarActions),
              ),
              ...AppBarHelper.adicionarBotaoRelatarProblema(context),
            ],
            bottom: provider.groups.isEmpty
                ? null
                : PreferredSize(
                    preferredSize: Size.fromHeight(appBarBottomHeight),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_showToolbarActions)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.tonal(
                                        onPressed: () => setState(() => _toolbarMenuTab = 0),
                                        child: Text(
                                          'Grupos',
                                          style: TextStyle(
                                            fontWeight: _toolbarMenuTab == 0 ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: FilledButton.tonal(
                                        onPressed: () => setState(() => _toolbarMenuTab = 1),
                                        child: Text(
                                          'Marcadores',
                                          style: TextStyle(
                                            fontWeight: _toolbarMenuTab == 1 ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_toolbarMenuTab == 0)
                                  SizedBox(
                                    height: 220,
                                    child: ListView(
                                      children: [
                                        DropdownButtonFormField<int>(
                                          isExpanded: true,
                                          initialValue: provider.activeGroup?.id,
                                          items: provider.groups
                                              .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name, overflow: TextOverflow.ellipsis)))
                                              .toList(),
                                          onChanged: (id) {
                                            if (id != null) provider.switchGroup(id);
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton(
                                              onPressed: _goToMyLocation,
                                              child: const Text('📍 Minha localização'),
                                            ),
                                            OutlinedButton(
                                              onPressed: _showAlertRadiusSettings,
                                              child: const Text('⚠ Raio'),
                                            ),
                                            OutlinedButton(
                                              onPressed: () => _showPendingInvitesDialog(provider),
                                              child: Text('✉ Convites (${provider.pendingInvites.length})'),
                                            ),
                                            if (provider.activeGroup != null)
                                              OutlinedButton(
                                                onPressed: () => _showMembersSheet(provider),
                                                child: Text(canManageGroup ? '👥 Gerenciar membros' : '👥 Ver membros'),
                                              ),
                                            if (provider.activeGroup != null && canManageGroup)
                                              OutlinedButton(
                                                onPressed: () => _showInviteDialog(provider),
                                                child: const Text('➕ Convidar'),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...provider.groups.map(
                                          (g) => ListTile(
                                            dense: true,
                                            title: Text(g.name, overflow: TextOverflow.ellipsis),
                                            subtitle: Text(g.id == provider.activeGroup?.id ? 'Grupo ativo' : 'Toque para ativar'),
                                            leading: Icon(g.id == provider.activeGroup?.id ? Icons.check_circle : Icons.group),
                                            onTap: () => provider.switchGroup(g.id),
                                            trailing: TextButton(
                                              onPressed: () => _confirmLeaveGroup(provider, g.id, g.name),
                                              child: const Text('Sair'),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  SizedBox(
                                    height: 220,
                                    child: ListView.separated(
                                      itemCount: provider.allPoints.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final point = provider.allPoints[index];
                                        return ListTile(
                                          dense: true,
                                          title: Text(point.title, overflow: TextOverflow.ellipsis),
                                          subtitle: Text('${point.type} • ${point.mapType}'),
                                          trailing: canManageGroup
                                              ? PopupMenuButton<String>(
                                                  onSelected: (value) async {
                                                    if (value == 'edit') {
                                                      await _showEditPointDialog(provider, point);
                                                    } else if (value == 'delete') {
                                                      final ok = await provider.deletePoint(point.id);
                                                      if (!mounted) return;
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        ok
                                                            ? AppStyles.successSnackBar('Marcador excluído.')
                                                            : AppStyles.errorSnackBar(provider.errorMessage ?? 'Erro ao excluir marcador.'),
                                                      );
                                                    }
                                                  },
                                                  itemBuilder: (_) => const [
                                                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                                                    PopupMenuItem(value: 'delete', child: Text('Excluir')),
                                                  ],
                                                )
                                              : null,
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Operacional'),
                            Tab(text: 'Logística'),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
          body: _buildBody(provider),
          floatingActionButton: provider.activeGroup != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'nav_mode_btn',
                      onPressed: _toggleNavigationMode,
                      tooltip: _navigationModeEnabled ? 'Desativar modo navegação' : 'Ativar modo navegação',
                      child: Text(_navigationModeEnabled ? '🧭' : '🧭'),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'sound_alert_btn',
                      onPressed: _toggleSoundAlert,
                      tooltip: _soundAlertEnabled ? 'Desativar aviso sonoro' : 'Ativar aviso sonoro',
                      child: Text(_soundAlertEnabled ? '🔊' : '🔈'),
                    ),
                    if (!provider.isMuted) ...[
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'create_point_btn',
                        onPressed: _openCriarPonto,
                        tooltip: 'Criar ponto',
                        child: const Text('📍'),
                      ),
                    ],
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(MapaTaticoProvider provider) {
    if (provider.isLoading && provider.groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.group_add, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Você ainda não participa de nenhum grupo.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Crie um grupo para começar a compartilhar pontos no mapa.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showCriarGrupoDialog(provider),
                icon: const Icon(Icons.add),
                label: const Text('Criar Grupo'),
              ),
              if (provider.pendingInvites.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _showPendingInvitesDialog(provider),
                  icon: const Icon(Icons.mail_outline),
                  label: Text('Ver ${provider.pendingInvites.length} convite(s) pendente(s)'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final points = provider.activeGroup != null
        ? (_tabController.index == 0 ? provider.pointsOperational : provider.pointsLogistics)
        : <MapPoint>[];

    final currentLatLng = provider.currentPosition != null
        ? LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude)
        : null;

    if (_navigationModeEnabled && currentLatLng != null) {
      final shouldRecenter = _lastCenteredPosition == null ||
          const Distance().as(LengthUnit.Meter, _lastCenteredPosition!, currentLatLng) > 7;
      if (shouldRecenter) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapController.move(currentLatLng, 16);
          _lastCenteredPosition = currentLatLng;
        });
      }
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(-14.2350, -51.9253),
            initialZoom: 4.5,
            minZoom: 3,
            maxZoom: 18,
            initialRotation: 0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            if (currentLatLng != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: currentLatLng,
                    radius: provider.alertRadiusMeters,
                    useRadiusInMeter: true,
                    color: provider.hasNearbyPointInAlertRadius
                        ? Colors.red.withAlpha(55)
                        : Colors.lightBlueAccent.withAlpha(55),
                    borderStrokeWidth: 2,
                    borderColor: provider.hasNearbyPointInAlertRadius
                        ? Colors.red.withAlpha(150)
                        : Colors.lightBlue.withAlpha(150),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                ...points.map(
                  (p) => Marker(
                    point: LatLng(p.lat, p.lng),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => context.push('/mapa-tatico/ponto/${p.id}'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _markerColorForPointType(p),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            _markerEmojiForPointType(p),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (provider.currentPosition != null)
                  Marker(
                    point: LatLng(
                      provider.currentPosition!.latitude,
                      provider.currentPosition!.longitude,
                    ),
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          '🚓',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (provider.isLoading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Color _markerColorForPointType(MapPoint p) {
    switch (p.type) {
      case 'ocorrencia_recente':
        return Colors.red;
      case 'suspeito':
        return Colors.red;
      case 'local_interesse':
        return Colors.amber;
      case 'restaurante':
        return Colors.green;
      case 'padaria':
        return Colors.brown;
      case 'base':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _markerEmojiForPointType(MapPoint p) {
    switch (p.type) {
      case 'suspeito':
        return '🏃';
      case 'ocorrencia_recente':
        return '❗';
      case 'local_interesse':
        return '📍';
      case 'restaurante':
        return '🍽';
      case 'padaria':
        return '🥖';
      case 'base':
        return '🛡';
      default:
        return '📍';
    }
  }

  void _showCriarGrupoDialog(MapaTaticoProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Criar Grupo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome do grupo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final group = await provider.createGroup(name);
              if (group != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  AppStyles.successSnackBar('Grupo criado com sucesso!'),
                );
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}
