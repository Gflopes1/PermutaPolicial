import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_styles.dart';
import '../../../shared/widgets/app_bar_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/group_invite.dart';
import '../models/map_group_member.dart';
import '../models/map_point.dart';
import '../models/mapa_tatico_filters.dart';
import '../providers/mapa_tatico_provider.dart';
import '../utils/mapa_tatico_marker_utils.dart';
import '../widgets/mapa_tatico_filters_sheet.dart';
import '../widgets/mapa_tatico_group_panel.dart';
import '../widgets/mapa_tatico_map_widget.dart';
import '../widgets/mapa_tatico_point_preview_sheet.dart';
import '../widgets/mapa_tatico_quick_create_sheet.dart';

class MapaTaticoScreen extends StatefulWidget {
  const MapaTaticoScreen({super.key});

  @override
  State<MapaTaticoScreen> createState() => _MapaTaticoScreenState();
}

class _MapaTaticoScreenState extends State<MapaTaticoScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late TabController _mapTypeTabController;
  MapaTaticoProvider? _mapaTaticoProvider;
  int _bottomNavIndex = 0;
  bool _soundAlertEnabled = true;
  bool _navigationModeEnabled = false;
  LatLng? _lastCenteredPosition;
  bool _showLongPressHint = false;
  bool _longPressHintShown = false;
  Timer? _longPressHintTimer;

  @override
  void initState() {
    super.initState();
    _mapTypeTabController = TabController(length: 3, vsync: this);
    _mapTypeTabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MapaTaticoProvider>();
      final auth = context.read<AuthProvider>();
      _mapaTaticoProvider = provider;
      provider.setCurrentUserId(auth.user?.id);
      provider.onProximityAlert = (point) => _showProximityAlert(point);
      await provider.loadPreferences();
      // Socket e grupos em paralelo: a conexão do socket não bloqueia o mapa.
      await Future.wait([
        provider.initializeRealtime(),
        provider.loadGroups(),
      ]);
      provider.setAppInForeground(true);
      if (!kIsWeb) {
        unawaited(provider.requestAndRefreshCurrentLocation());
      }
      _maybeShowLongPressHint();
    });
  }

  void _maybeShowLongPressHint() {
    if (_longPressHintShown || !mounted) return;
    final provider = context.read<MapaTaticoProvider>();
    if (provider.groups.isEmpty || _bottomNavIndex != 0) return;
    _longPressHintShown = true;
    setState(() => _showLongPressHint = true);
    _longPressHintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showLongPressHint = false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<MapaTaticoProvider>().setAppInForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    _longPressHintTimer?.cancel();
    _mapTypeTabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _mapaTaticoProvider?.setAppInForeground(false);
    super.dispose();
  }

  String _activeMapTypeFor(MapaTaticoProvider provider) {
    // Sem grupo fechado, só o Mapa Nacional está disponível.
    if (provider.privateGroups.isEmpty) {
      return 'NATIONAL';
    }
    switch (_mapTypeTabController.index) {
      case 1:
        return 'LOGISTICS';
      case 2:
        return 'NATIONAL';
      default:
        return 'OPERATIONAL';
    }
  }

  void _showProximityAlert(MapPoint point) {
    if (!mounted) return;
    if (_soundAlertEnabled) {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Ponto operacional próximo: ${point.title}')),
            ],
          ),
          backgroundColor: Colors.deepOrange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Ver',
            textColor: Colors.white,
            onPressed: () => _showPointPreview(point),
          ),
        ),
      );
  }

  void _showPointPreview(MapPoint point) {
    final provider = context.read<MapaTaticoProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => MapaTaticoPointPreviewSheet(point: point, isMuted: provider.isMuted),
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
            provider.errorMessage ?? provider.locationUnavailableMessage,
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

  Future<void> _openFilters(MapaTaticoProvider provider) async {
    final mapType = _activeMapTypeFor(provider);
    final initial = mapType == 'LOGISTICS' ? provider.filtersLogistics : provider.filtersOperational;
    final result = await showModalBottomSheet<MapaTaticoFilters>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MapaTaticoFiltersSheet(mapType: mapType, initialFilters: initial),
    );
    if (result == null) return;
    if (mapType == 'LOGISTICS') {
      provider.setFiltersLogistics(result);
    } else if (mapType != 'NATIONAL') {
      provider.setFiltersOperational(result);
    }
  }

  void _openQuickCreate(LatLng position) {
    final provider = context.read<MapaTaticoProvider>();
    final mapType = _activeMapTypeFor(provider);
    if (mapType == 'NATIONAL') {
      if (provider.globalGroup == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.errorSnackBar('Mapa Nacional indisponível.'),
        );
        return;
      }
    } else if (provider.activeGroup == null || provider.activeGroup!.isGlobal) {
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
      builder: (_) => MapaTaticoQuickCreateSheet(
        lat: position.latitude,
        lng: position.longitude,
        mapType: mapType,
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
            title: const Text('Raio de alerta (operacional)'),
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          );
        },
      ),
    );
  }

  bool _canManageGroup(MapaTaticoProvider provider) {
    final user = context.read<AuthProvider>().user;
    return provider.activeGroup?.isModerator == true ||
        user?.isModerator == true ||
        user?.isEmbaixador == true;
  }

  bool _canEditPoint(MapaTaticoProvider provider, MapPoint point) {
    if (_canManageGroup(provider)) return true;
    final userId = context.read<AuthProvider>().user?.id;
    return userId != null && point.creatorId == userId;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapaTaticoProvider>(
      builder: (context, provider, _) {
        final canManage = _canManageGroup(provider);
        final hasPrivateGroups = provider.privateGroups.isNotEmpty;
        final activeMapType = _activeMapTypeFor(provider);
        final points = switch (activeMapType) {
          'LOGISTICS' => provider.pointsLogistics,
          'NATIONAL' => provider.pointsNational,
          _ => provider.pointsOperational,
        };

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mapa Tático e Logístico'),
            actions: [
              if (_bottomNavIndex == 0) ...[
                if (hasPrivateGroups) ...[
                  IconButton(
                    icon: Icon(provider.sharingLocationEnabled ? Icons.location_on : Icons.location_off),
                    tooltip: 'Compartilhar posição com o grupo',
                    onPressed: () => provider.setSharingLocation(!provider.sharingLocationEnabled),
                  ),
                  IconButton(
                    icon: const Icon(Icons.insights),
                    tooltip: 'Inteligência do grupo',
                    onPressed: () => context.push('/mapa-tatico/inteligencia'),
                  ),
                ],
                if (activeMapType != 'NATIONAL')
                  IconButton(
                    icon: const Icon(Icons.filter_alt),
                    tooltip: 'Filtros',
                    onPressed: () => _openFilters(provider),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Atualizar pontos',
                  onPressed: () => provider.loadPoints(),
                ),
                IconButton(
                  icon: const Icon(Icons.my_location),
                  tooltip: 'Minha localização',
                  onPressed: _goToMyLocation,
                ),
                IconButton(
                  icon: const Icon(Icons.radar),
                  tooltip: 'Raio de alerta',
                  onPressed: _showAlertRadiusSettings,
                ),
              ],
              ...AppBarHelper.adicionarBotaoRelatarProblema(context),
            ],
            bottom: !hasPrivateGroups || _bottomNavIndex != 0
                ? null
                : TabBar(
                    controller: _mapTypeTabController,
                    tabs: const [
                      Tab(text: 'Operacional'),
                      Tab(text: 'Logística'),
                      Tab(text: 'Nacional'),
                    ],
                  ),
          ),
          body: _buildBody(provider, points, canManage, activeMapType),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _bottomNavIndex,
            onDestinationSelected: (i) => setState(() => _bottomNavIndex = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.map), label: 'Mapa'),
              NavigationDestination(icon: Icon(Icons.list), label: 'Lista'),
              NavigationDestination(icon: Icon(Icons.group), label: 'Grupo'),
            ],
          ),
          floatingActionButton: _bottomNavIndex == 0 && provider.activeGroup != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'nav_mode_btn',
                      backgroundColor: _navigationModeEnabled ? Colors.blue : null,
                      foregroundColor: _navigationModeEnabled ? Colors.white : null,
                      onPressed: () {
                        setState(() {
                          _navigationModeEnabled = !_navigationModeEnabled;
                          _lastCenteredPosition = null;
                        });
                        if (_navigationModeEnabled) {
                          unawaited(context.read<MapaTaticoProvider>().requestAndRefreshCurrentLocation());
                          _goToMyLocation();
                        }
                      },
                      tooltip: 'Modo navegação',
                      child: const Icon(Icons.navigation),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'sound_alert_btn',
                      onPressed: () {
                        setState(() => _soundAlertEnabled = !_soundAlertEnabled);
                        ScaffoldMessenger.of(context).showSnackBar(
                          AppStyles.successSnackBar(
                            _soundAlertEnabled ? 'Aviso sonoro ativado.' : 'Aviso sonoro desativado.',
                          ),
                        );
                      },
                      child: Text(_soundAlertEnabled ? '🔊' : '🔈'),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(MapaTaticoProvider provider, List<MapPoint> points, bool canManage, String activeMapType) {
    switch (_bottomNavIndex) {
      case 1:
        return RefreshIndicator(
          onRefresh: provider.loadPoints,
          child: points.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(child: Text('Nenhum marcador nesta aba.')),
                  ],
                )
              : ListView.separated(
                  itemCount: points.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final point = points[index];
                    final distance = provider.distanceToPoint(point);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: markerColorForPointType(point),
                        child: Text(markerEmojiForPointType(point), style: const TextStyle(fontSize: 14)),
                      ),
                      title: Text(point.title),
                      subtitle: Text(
                        [
                          pointTypeLabel(point.type),
                          if (distance != null) '${distance.toStringAsFixed(0)} m',
                          if (point.expiresAt != null) formatExpiresLabel(point.expiresAt),
                        ].where((e) => e.isNotEmpty).join(' • '),
                      ),
                      onTap: () => _showPointPreview(point),
                      trailing: _canEditPoint(provider, point)
                          ? PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'delete') {
                                  final ok = await provider.deletePoint(point.id);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    ok
                                        ? AppStyles.successSnackBar('Marcador excluído.')
                                        : AppStyles.errorSnackBar(provider.errorMessage ?? 'Erro ao excluir.'),
                                  );
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'delete', child: Text('Excluir')),
                              ],
                            )
                          : null,
                    );
                  },
                ),
        );
      case 2:
        return MapaTaticoGroupPanel(
          provider: provider,
          canManageGroup: canManage,
          onCreateGroup: () => _showCriarGrupoDialog(provider),
          onSwitchGroup: (id) => provider.switchGroup(id),
          onLeaveGroup: (id, name) => _confirmLeaveGroup(provider, id, name),
          onShowInvites: () => _showPendingInvitesDialog(provider),
          onShowMembers: () => _showMembersSheet(provider),
          onInvite: () => _showInviteDialog(provider),
        );
      default:
        // Primeira carga: evita mostrar "nenhum grupo" antes dos dados chegarem.
        if (provider.groups.isEmpty) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando mapa e grupos...'),
                ],
              ),
            );
          }
          return MapaTaticoGroupPanel(
            provider: provider,
            canManageGroup: canManage,
            onCreateGroup: () => _showCriarGrupoDialog(provider),
            onSwitchGroup: (id) => provider.switchGroup(id),
            onLeaveGroup: (id, name) => _confirmLeaveGroup(provider, id, name),
            onShowInvites: () => _showPendingInvitesDialog(provider),
            onShowMembers: () => _showMembersSheet(provider),
            onInvite: () => _showInviteDialog(provider),
          );
        }
        return Stack(
          children: [
            MapaTaticoMapWidget(
              mapController: _mapController,
              points: points,
              mapType: activeMapType,
              navigationModeEnabled: _navigationModeEnabled,
              routePoints: provider.navigationRoute,
              lastCenteredPosition: _lastCenteredPosition,
              onNavigationRecenter: (latLng) {
                if (!mounted || !_navigationModeEnabled) return;
                var zoom = 16.0;
                try {
                  zoom = _mapController.camera.zoom;
                } catch (_) {}
                _mapController.move(latLng, zoom);
                _lastCenteredPosition = latLng;
              },
              onPointTap: _showPointPreview,
              onLongPress: _openQuickCreate,
            ),
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showLongPressHint ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 350),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 80, left: 24, right: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Clique e segure no mapa para adicionar um marcador',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Column(
                children: [
                  if (provider.privateGroups.isEmpty)
                    Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blueGrey.shade900,
                      child: ListTile(
                        leading: const Icon(Icons.public, color: Colors.lightBlueAccent),
                        title: const Text('Você está no Mapa Nacional'),
                        subtitle: const Text(
                          'Você ainda não participa de nenhum grupo fechado. '
                          'Crie um grupo ou aceite um convite para usar os mapas Operacional e Logístico.',
                        ),
                        trailing: FilledButton(
                          onPressed: () => setState(() => _bottomNavIndex = 2),
                          child: const Text('Grupos'),
                        ),
                      ),
                    ),
                  if (provider.privateGroups.isEmpty && provider.currentPosition == null)
                    const SizedBox(height: 8),
                  if (provider.currentPosition == null)
                    Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(8),
                      child: ListTile(
                        leading: const Icon(Icons.location_disabled, color: Colors.orange),
                        title: Text(kIsWeb ? 'Localização não ativa' : 'GPS indisponível'),
                        subtitle: Text(
                          kIsWeb
                              ? 'Toque para permitir o acesso à localização no navegador.'
                              : provider.locationUnavailableMessage,
                        ),
                        trailing: FilledButton(
                          onPressed: _goToMyLocation,
                          child: const Text('Ativar'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
    }
  }

  // --- Diálogos de grupo (mantidos) ---

  void _showCriarGrupoDialog(MapaTaticoProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Criar Grupo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome do grupo', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
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

  Future<void> _showPendingInvitesDialog(MapaTaticoProvider provider) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => Consumer<MapaTaticoProvider>(
        builder: (context, liveProvider, _) {
          final invites = liveProvider.pendingInvites;
          return AlertDialog(
            title: const Text('Convites pendentes'),
            content: SizedBox(
              width: 460,
              child: invites.isEmpty
                  ? const Text('Nenhum convite pendente.')
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: invites.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final invite = invites[index];
                        return ListTile(
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
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Fechar')),
            ],
          );
        },
      ),
    );
  }

  Future<void> _acceptInvite(MapaTaticoProvider provider, GroupInvite invite) async {
    try {
      await provider.acceptInvite(invite.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(AppStyles.successSnackBar('Convite aceito!'));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar(provider.errorMessage ?? 'Erro ao aceitar convite.'),
      );
    }
  }

  Future<void> _rejectInvite(MapaTaticoProvider provider, GroupInvite invite) async {
    try {
      await provider.rejectInvite(invite.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(AppStyles.successSnackBar('Convite recusado.'));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar(provider.errorMessage ?? 'Erro ao recusar convite.'),
      );
    }
  }

  void _showInviteDialog(MapaTaticoProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Convidar usuário'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final email = controller.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await provider.inviteToGroup(email);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  AppStyles.successSnackBar('Convite enviado!'),
                );
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  AppStyles.errorSnackBar(provider.errorMessage ?? 'Erro ao enviar convite.'),
                );
              }
            },
            child: const Text('Enviar'),
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
      ScaffoldMessenger.of(context).showSnackBar(AppStyles.successSnackBar('Você saiu do grupo.'));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar(provider.errorMessage ?? 'Não foi possível sair do grupo.'),
      );
    }
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

            return FractionallySizedBox(
              heightFactor: 0.82,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Membros de ${provider.activeGroup!.name}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                            return const Center(child: Text('Nenhum membro encontrado.'));
                          }
                          return ListView.separated(
                            itemCount: members.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final member = members[index];
                              return ListTile(
                                title: Text(member.displayName),
                                subtitle: Text(member.email ?? ''),
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
}
