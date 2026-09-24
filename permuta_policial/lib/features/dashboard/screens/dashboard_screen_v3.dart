// /lib/features/dashboard/screens/dashboard_screen_v3.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/announcement_service.dart';
import '../../../core/utils/app_share.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_status.dart';
import '../../referral/providers/referral_provider.dart';
import '../../referral/widgets/referral_dashboard_card.dart';
import '../../notificacoes/widgets/app_announcement_modal.dart';

import '../providers/dashboard_provider.dart';
import '../../../core/config/app_router.dart';
import '../../../core/models/match_results.dart';
import '../../../core/models/parceiro.dart';
import '../../../core/models/consultoria_advogado.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/utils/profile_completion.dart';
import '../widgets/parceiros_card.dart';
import '../widgets/dashboard_onboarding.dart';
import '../widgets/minesweeper_game.dart';
import '../widgets/dashboard_pix_footer.dart';
import '../widgets/dashboard_desktop_layout.dart';
import '../../../shared/widgets/network_error_panel.dart';
import '../../notificacoes/providers/notificacoes_provider.dart';
import '../../chat/providers/chat_provider.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../marketplace/providers/marketplace_provider.dart';
import '../../marketplace/screens/marketplace_photo_picker_screen.dart';
import '../../permutas/providers/permutas_inteligentes_provider.dart';
import '../../permutas/utils/permutas_unificadas_utils.dart';
import '../../../core/models/smart_match_results.dart';
import '../../permutas/utils/permuta_contact_actions.dart';
import '../../consultoria_juridica/screens/consultoria_advogados_list_screen.dart';
import '../../forum/screens/forum_list_screen.dart';

/// Dashboard v3 — layout mobile-first baseado no mockup permuta_policial_v3.html
class DashboardScreenV3 extends StatefulWidget {
  const DashboardScreenV3({super.key});

  @override
  State<DashboardScreenV3> createState() => _DashboardScreenV3State();
}

class _DashboardScreenV3State extends State<DashboardScreenV3> {
  static const _shareAppText =
      'Conheça o Permuta Policial — plataforma para permutas entre agentes de segurança pública https://permutapolicial.com.br';

  DateTime? _lastBackPressTime;
  bool _postLoadDone = false;
  DashboardProvider? _dashboardProvider;
  final ScrollController _scrollController = ScrollController();

  // Paleta v3
  static const _bg = Color(0xFF0F1117);
  static const _card = Color(0xFF1C1F28);
  static const _border = Color(0xFF2A2D36);
  static const _heroBlue = Color(0xFF1565C0);
  static const _accent = Color(0xFF4A90D9);
  static const _muted = Color(0x8FFFFFFF);

  @override
  void dispose() {
    _dashboardProvider?.removeListener(_onProviderReady);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackPageView();
      _dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      _dashboardProvider!.addListener(_onProviderReady);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final cachedProfile =
          auth.status == AuthStatus.authenticated ? auth.user : null;
      _dashboardProvider!.fetchInitialData(cachedProfile: cachedProfile);
      Provider.of<PermutasInteligentesProvider>(context, listen: false).fetchSummary();
      Provider.of<PermutasInteligentesProvider>(context, listen: false).fetchMatches();
      final notif = Provider.of<NotificacoesProvider>(context, listen: false);
      notif.loadNotificacoes();
      notif.bindSocketRefresh(Provider.of<SocketService>(context, listen: false));
      final chat = Provider.of<ChatProvider>(context, listen: false);
      chat.initializeSocket();
      chat.loadMensagensNaoLidas();
      Provider.of<ReferralProvider>(context, listen: false).loadMyReferral();
      if ((_dashboardProvider!.userData?.isEmbaixador ?? false) ||
          (_dashboardProvider!.userData?.isModerator ?? false)) {
        Provider.of<MarketplaceProvider>(context, listen: false).loadPendentesCount();
      }
      if (!_dashboardProvider!.isLoadingInitialData) _onProviderReady();
    });
  }

  void _onProviderReady() {
    final p = _dashboardProvider;
    if (p == null || p.isLoadingInitialData || _postLoadDone) return;
    _postLoadDone = true;
    p.removeListener(_onProviderReady);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPostLoadActions());
  }

  Future<void> _runPostLoadActions() async {
    if (!mounted) return;
    try {
      await DashboardOnboarding.showIfNeeded(context);
      if (!mounted) return;
      await _verificarAtualizacao();
    } catch (e, st) {
      debugPrint('⚠️ Dashboard v3 pós-carregamento: $e\n$st');
    }
  }

  Future<void> _trackPageView() async {
    try {
      await Provider.of<AnalyticsService>(context, listen: false).trackPageView('/dashboard-v3');
    } catch (_) {}
  }

  Future<void> _verificarAtualizacao() async {
    try {
      final announcementSvc = Provider.of<AnnouncementService>(context, listen: false);
      final campaign = await announcementSvc.getNextPendingCampaign();
      if (campaign == null || !mounted) return;

      final referralProvider = Provider.of<ReferralProvider>(context, listen: false);
      await referralProvider.loadMyReferral();
      final link = referralProvider.data?.link ?? 'https://br.permutapolicial.com.br';

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AppAnnouncementModal(
          campaign: campaign,
          onPrimary: () async {
            await announcementSvc.dismissCampaign(campaign);
            if (ctx.mounted) Navigator.of(ctx).pop();
            if (campaign.primaryAction == 'referral' && mounted) {
              context.push(AppRoutes.referral);
            }
          },
          onSecondary: campaign.secondaryLabel != null
              ? () async {
                  await announcementSvc.dismissCampaign(campaign);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                }
              : null,
          onShare: campaign.showShare
              ? () async {
                  final text = ReferralProvider.sharePopupMessage(link);
                  await shareText(text, subject: 'Permuta Policial');
                  await referralProvider.trackShare();
                }
              : null,
        ),
      );

      _showNewReferralSnackBar();
    } catch (_) {}
  }

  void _showNewReferralSnackBar() {
    final referral = Provider.of<ReferralProvider>(context, listen: false);
    final count = referral.newVerifiedSinceLastVisit;
    if (count <= 0 || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 1
              ? '🎉 Novo colega verificado! Você trouxe ${referral.data?.verifiedCount ?? count} policiais.'
              : '🎉 $count novos colegas verificados!',
        ),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () => context.push(AppRoutes.referral),
        ),
      ),
    );
    referral.acknowledgeVerifiedCount();
  }

  int _compatibleMatchesCount(DashboardProvider p, PermutasInteligentesProvider pi) {
    return PermutasUnificadasUtils.countCompativelDashboard(p.matches, pi.results);
  }

  List<_CompatiblePreviewItem> _compatiblePreview(
    DashboardProvider p,
    PermutasInteligentesProvider pi,
  ) {
    final items = <_CompatiblePreviewItem>[];
    final piResults = pi.results;
    final m = p.matches;
    final piIds = piResults != null ? PermutasUnificadasUtils.piPolicialIds(piResults) : <int>{};
    final piExactTri =
        piResults != null ? PermutasUnificadasUtils.piTriangularesExatas(piResults) : const <MatchTriangular>[];

    if (piResults != null) {
      for (final d in piResults.diretas) {
        items.add(_CompatiblePreviewItem.direct(d));
        if (items.length >= 3) return items;
      }
      for (final t in piExactTri) {
        items.add(_CompatiblePreviewItem.triangular(t));
        if (items.length >= 3) return items;
      }
    }

    if (m != null) {
      for (final d in PermutasUnificadasUtils.filterOriginalMatches(m.diretas, piIds)) {
        items.add(_CompatiblePreviewItem.direct(d));
        if (items.length >= 3) return items;
      }
      for (final t in PermutasUnificadasUtils.filterDuplicateTriangulares(m.triangulares, piExactTri)) {
        items.add(_CompatiblePreviewItem.triangular(t));
        if (items.length >= 3) return items;
      }
    }

    for (final c in piResults?.ciclosN ?? const <CicloNWay>[]) {
      items.add(_CompatiblePreviewItem.ciclo(c));
      if (items.length >= 3) return items;
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressTime != null &&
            now.difference(_lastBackPressTime!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
        } else {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pressione voltar novamente para sair')),
          );
        }
      },
      child: Theme(
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: _bg,
          colorScheme: const ColorScheme.dark(
            primary: _accent,
            surface: _card,
          ),
        ),
        child: Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Consumer<DashboardProvider>(
              builder: (context, provider, _) {
                if (provider.isLoadingInitialData && provider.userData == null) {
                  return const Center(child: CircularProgressIndicator(color: _accent));
                }
                if (provider.initialDataError != null) {
                  return _buildError(provider);
                }
                return Column(
                  children: [
                    _buildTopBar(context),
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: RefreshIndicator(
                              color: _accent,
                              onRefresh: () async {
                                await provider.fetchInitialData();
                                await Provider.of<PermutasInteligentesProvider>(context, listen: false)
                                    .fetchMatches();
                                Provider.of<NotificacoesProvider>(context, listen: false).refreshCount();
                              },
                              child: ListView(
                                controller: _scrollController,
                                padding: const EdgeInsets.only(bottom: 8),
                                children: [
                                  DashboardDesktopLayout(
                                  leftColumn: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildHero(context, provider),
                                      const SizedBox(height: 12),
                                      const ReferralDashboardCard(),
                                      const SizedBox(height: 12),
                                      _buildSectionTitle('Acesso rápido'),
                                      _buildQuickAccess(context),
                                      if (provider.consultoriaAdvogados.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        _buildConsultoriaEntry(context, provider),
                                      ],
                                      const SizedBox(height: 16),
                                      _buildMatchesSection(context, provider),
                                    ],
                                  ),
                                  rightColumn: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (provider.parceiros.isNotEmpty) ...[
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: ParceirosCard(
                                            parceiros: provider.parceiros
                                                .map((p) => Parceiro.fromJson(
                                                      Map<String, dynamic>.from(p as Map),
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                      _buildSectionTitle('Ferramentas'),
                                      _buildToolsGrid(context, provider),
                                      const SizedBox(height: 16),
                                      _buildDivider(),
                                      _buildSectionTitle('Comunidade'),
                                      _buildCommunityLinks(context, provider),
                                      const SizedBox(height: 12),
                                      _buildPermutasInteligentesCard(context),
                                      const SizedBox(height: 12),
                                      _buildCampoMinadoCard(context),
                                      const SizedBox(height: 12),
                                      const DashboardPixFooter(),
                                    ],
                                  ),
                                  mobileColumn: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildHero(context, provider),
                                      const SizedBox(height: 12),
                                      const ReferralDashboardCard(),
                                      const SizedBox(height: 12),
                                      _buildSectionTitle('Acesso rápido'),
                                      _buildQuickAccess(context),
                                      if (provider.consultoriaAdvogados.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        _buildConsultoriaEntry(context, provider),
                                      ],
                                      const SizedBox(height: 16),
                                      _buildMatchesSection(context, provider),
                                      if (provider.parceiros.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: ParceirosCard(
                                            parceiros: provider.parceiros
                                                .map((p) => Parceiro.fromJson(
                                                      Map<String, dynamic>.from(p as Map),
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      _buildDivider(),
                                      _buildSectionTitle('Ferramentas'),
                                      _buildToolsGrid(context, provider),
                                      const SizedBox(height: 16),
                                      _buildDivider(),
                                      _buildSectionTitle('Comunidade'),
                                      _buildCommunityLinks(context, provider),
                                      const SizedBox(height: 12),
                                      _buildPermutasInteligentesCard(context),
                                      const SizedBox(height: 12),
                                      _buildCampoMinadoCard(context),
                                      const SizedBox(height: 12),
                                      const DashboardPixFooter(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 72),
                              ],
                            ),
                          ),
                        ),
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: FloatingActionButton(
                              onPressed: _shareApp,
                              backgroundColor: _heroBlue,
                              tooltip: 'Compartilhar app',
                              child: const Icon(Icons.share, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          bottomNavigationBar: MediaQuery.sizeOf(context).width >= kDashboardDesktopBreakpoint
              ? null
              : _buildBottomNav(context),
        ),
      ),
    );
  }

  Widget _buildError(DashboardProvider provider) {
    return NetworkErrorPanel(
      error: provider.initialDataError ?? 'Erro desconhecido',
      onRetry: () => provider.fetchInitialData(
        cachedProfile: context.read<AuthProvider>().user,
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'images/ic_launcher.png',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Permuta Policial',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Consumer<NotificacoesProvider>(
            builder: (context, notif, _) {
              final count = notif.countNaoLidas;
              return IconButton(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text(count > 9 ? '9+' : '$count'),
                  child: const Icon(Icons.notifications_outlined, color: _muted),
                ),
                onPressed: () => context.push(AppRoutes.notificacoes),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: _muted),
            tooltip: 'Opções',
            onSelected: (v) => _onProfileMenu(context, v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'dados', child: Text('Meus dados')),
              const PopupMenuItem(value: 'help', child: Text('Ajuda')),
              const PopupMenuItem(value: 'share', child: Text('Compartilhar app')),
              const PopupMenuItem(value: 'anuncio', child: Text('Criar anúncio')),
              const PopupMenuItem(value: 'logout', child: Text('Sair')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareApp() async {
    final shared = await shareText(_shareAppText, subject: 'Permuta Policial');
    if (!shared && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Texto copiado! Cole onde quiser compartilhar.')),
      );
    }
  }

  void _onProfileMenu(BuildContext context, String action) async {
    switch (action) {
      case 'dados':
        context.push(AppRoutes.meusDados);
        break;
      case 'help':
        launchUrl(Uri.parse('https://br.permutapolicial.com.br/help.html'),
            mode: LaunchMode.externalApplication);
        break;
      case 'share':
        await _shareApp();
        break;
      case 'anuncio':
        final provider = Provider.of<DashboardProvider>(context, listen: false);
        final result = await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MarketplacePhotoPickerScreen()),
        );
        if (result == true && context.mounted) provider.fetchInitialData();
        break;
      case 'logout':
        await Provider.of<DashboardProvider>(context, listen: false).logout();
        if (context.mounted) context.go(AppRoutes.auth);
        break;
    }
  }

  Widget _buildHero(BuildContext context, DashboardProvider provider) {
    final user = provider.userData;
    final nome = user?.nome ?? 'Usuário';
    final incompleto = isProfileIncomplete(user);
    final lotacaoParts = <String>[];
    final forca = user?.forcaSigla;
    if (forca != null && forca.isNotEmpty) lotacaoParts.add(forca);
    final unidade = user?.unidadeAtualNome;
    if (unidade != null && unidade.isNotEmpty) lotacaoParts.add(unidade);
    final posto = user?.postoGraduacaoNome;
    if (posto != null && posto.isNotEmpty) lotacaoParts.add(posto);
    final lotacao = lotacaoParts.join(' · ');

    final vagaAtiva = user?.unidadeAtualNome != null || user?.municipioAtualNome != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: _heroBlue,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Olá, $nome', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                      if (lotacao.isNotEmpty)
                        Text(lotacao, style: const TextStyle(color: _muted, fontSize: 11)),
                    ],
                  ),
                ),
                if (vagaAtiva)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Vaga ativa ✓', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
              ],
            ),
            if (incompleto) ...[
              const SizedBox(height: 10),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () => context.push(AppRoutes.completarPerfil),
                child: const Text('Completar perfil', style: TextStyle(fontSize: 11)),
              ),
            ],
            const SizedBox(height: 12),
            Consumer<PermutasInteligentesProvider>(
              builder: (context, pi, _) {
                final unified = provider.unifiedMetrics;
                final matches = unified?.dashboardMatchesCompativeis ??
                    _compatibleMatchesCount(provider, pi);
                final piIds = pi.results != null
                    ? PermutasUnificadasUtils.piPolicialIds(pi.results!)
                    : <int>{};
                final interessados = unified?.dashboardInteressados ??
                    PermutasUnificadasUtils.countInteressadosMatches(
                      provider.matches,
                      pi.results,
                      piIds,
                    );
                return Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push('${AppRoutes.permutas}?tab=interessados'),
                        borderRadius: BorderRadius.circular(10),
                        child: _heroStat('$interessados', 'Interessados na sua vaga'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push(AppRoutes.permutas),
                        borderRadius: BorderRadius.circular(10),
                        child: _heroStat('$matches', 'Matches compatíveis'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String n, String label) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(n, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onMore, String? moreLabel}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: Text(moreLabel ?? 'Ver todos', style: const TextStyle(color: _accent, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
        children: [
          _qaItem(Icons.psychology_outlined, 'Permutas\nInteligentes', () => context.push(AppRoutes.permutas)),
          _qaItem(Icons.map_outlined, 'Mapa de\nPermutas', () => context.push(AppRoutes.mapa)),
          _qaItem(Icons.map, 'Mapa\nTático', () => context.push(AppRoutes.mapaTatico)),
          _qaItem(Icons.description_outlined, 'Editais', () => context.push(AppRoutes.editaisHub)),
        ],
      ),
    );
  }

  Widget _qaItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _accent, size: 22),
            const SizedBox(height: 5),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 9, height: 1.3)),
          ],
        ),
      ),
    );
  }

  void _openConsultoria(BuildContext context, List<ConsultoriaAdvogado> advogados) {
    if (advogados.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConsultoriaAdvogadosListScreen(advogados: advogados),
      ),
    );
  }

  Widget _buildConsultoriaEntry(BuildContext context, DashboardProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: () => _openConsultoria(context, provider.consultoriaAdvogados),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2744),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.balance, color: _accent, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Consultoria jurídica', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    SizedBox(height: 3),
                    Text(
                      'Orientação sobre transferências, direitos e legislação policial',
                      style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0x40FFFFFF), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchesSection(BuildContext context, DashboardProvider provider) {
    return Consumer<PermutasInteligentesProvider>(
      builder: (context, pi, _) {
        final preview = _compatiblePreview(provider, pi);
        final total = _compatibleMatchesCount(provider, pi);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'Matches compatíveis',
              onMore: total > 0 ? () => context.push(AppRoutes.permutas) : null,
              moreLabel: total > 0 ? 'Ver todos ($total)' : null,
            ),
            if (provider.isLoadingMatches)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _accent)),
              )
            else if (preview.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  provider.userData != null && !isProfileIncomplete(provider.userData)
                      ? 'Nenhum match ainda. Ajuste suas intenções em Ambiente de Permutas.'
                      : 'Complete seu perfil para ver matches compatíveis.',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              )
            else
              ...preview.map((item) => _buildCompatiblePreviewCard(context, item)),
          ],
        );
      },
    );
  }

  Widget _buildCompatiblePreviewCard(BuildContext context, _CompatiblePreviewItem item) {
    final ciclo = item.ciclo;
    if (ciclo != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(AppRoutes.permutas),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border, width: 0.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1A2744),
                    child: Icon(Icons.link, color: _accent, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Permuta em cadeia',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        _tag('${ciclo.tamanho} pessoas', const Color(0xFF2F1F0A), const Color(0xFFFFB74D)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: _muted, size: 20),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final triangular = item.triangular;
    if (triangular != null) {
      return _buildMatchCard(context, triangular.policialB, isTriangular: true);
    }

    final match = item.match;
    if (match == null) return const SizedBox.shrink();

    return _buildMatchCard(context, match, isTriangular: false);
  }

  Widget _buildMatchCard(BuildContext context, Match match, {bool isTriangular = false}) {
    final loc = [
      match.forcaSigla,
      if (match.municipioAtual != null) match.municipioAtual,
      if (match.estadoAtual != null) match.estadoAtual,
    ].where((s) => s != null && s.isNotEmpty).join(' — ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(AppRoutes.permutas),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border, width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1A2744),
                  child: Icon(Icons.person, color: _accent, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(match.nome, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      if (isTriangular)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _tag('Permuta triangular', const Color(0xFF1A2744), _accent),
                        ),
                      if (loc.isNotEmpty)
                        Text(loc, style: const TextStyle(color: _muted, fontSize: 10)),
                      if (match.postoGraduacaoNome != null) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          children: [
                            _tag(match.postoGraduacaoNome!, const Color(0xFF1A2F1A), const Color(0xFF81C784)),
                            if (match.descricaoInteresse != null && match.descricaoInteresse!.isNotEmpty)
                              _tag(match.descricaoInteresse!, const Color(0xFF2F1F0A), const Color(0xFFFFB74D)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _heroBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => PermutaContactActions.enviarMensagemParaMatch(context, match),
                      child: const Text('Contato', style: TextStyle(fontSize: 10)),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.chevron_right, color: _muted, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildToolsGrid(BuildContext context, DashboardProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.6,
        children: [
          _toolCard(Icons.schedule, 'Gestor de Horas e Soldo', 'Escalas e etapas', () => context.push(AppRoutes.calendar)),
          _toolCard(Icons.school_outlined, 'Questões & Simulados', 'Prepare-se para provas', () => context.push(AppRoutes.questions)),
          _toolCard(Icons.shopping_bag_outlined, 'Marketplace', 'Anúncios e vendas', () => context.push(AppRoutes.marketplace)),
          _toolCard(Icons.swap_horiz, 'Ambiente de Permutas', 'Gerenciar sua vaga', () => context.push(AppRoutes.permutas)),
        ],
      ),
    );
  }

  Widget _toolCard(IconData icon, String title, String sub, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _accent, size: 20),
            const Spacer(),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            Text(sub, style: const TextStyle(color: _muted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityLinks(BuildContext context, DashboardProvider provider) {
    final user = provider.userData;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _listLink(Icons.forum_outlined, 'Fórum da Comunidade', () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForumListScreen()));
          }),
          if (user != null && (user.isEmbaixador || user.isModerator))
            _listLink(Icons.admin_panel_settings_outlined, 'Painel de Administração', () {
              context.push(AppRoutes.admin);
            }),
        ],
      ),
    );
  }

  Widget _listLink(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(icon, color: _accent, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13))),
              const Icon(Icons.chevron_right, color: Color(0x40FFFFFF), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermutasInteligentesCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Consumer<PermutasInteligentesProvider>(
        builder: (context, pi, _) {
          final count = pi.summaryCount ?? 0;
          return InkWell(
            onTap: () => context.push(AppRoutes.permutas),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _heroBlue, width: 1, strokeAlign: BorderSide.strokeAlignInside),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: _accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Permutas Inteligentes', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: _heroBlue, borderRadius: BorderRadius.circular(6)),
                              child: const Text('BETA', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                        Text(
                          'Motor gráfico · $count matches · ciclos N-way',
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0x40FFFFFF), size: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCampoMinadoCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MinesweeperGame()),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.grid_on, color: Colors.orange, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Campo Minado', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
              Icon(Icons.chevron_right, color: Color(0x40FFFFFF), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Divider(color: _border, height: 1),
      );

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161920),
        border: Border(top: BorderSide(color: _border, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home, 'Início', true, () {}),
          _navItem(Icons.swap_horiz, 'Permutas', false, () => context.push(AppRoutes.permutas)),
          _navItem(Icons.favorite_border, 'Matches', false, () => context.push(AppRoutes.permutas)),
          _navItem(Icons.chat_bubble_outline, 'Mensagens', false, () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatListScreen()));
          }),
          _navItem(Icons.person_outline, 'Perfil', false, () => context.push(AppRoutes.meusDados)),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap) {
    final color = active ? _accent : const Color(0x4DFFFFFF);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 8)),
        ],
      ),
    );
  }
}

class _CompatiblePreviewItem {
  final Match? match;
  final MatchTriangular? triangular;
  final CicloNWay? ciclo;

  const _CompatiblePreviewItem._({this.match, this.triangular, this.ciclo});

  factory _CompatiblePreviewItem.direct(Match m) =>
      _CompatiblePreviewItem._(match: m);

  factory _CompatiblePreviewItem.triangular(MatchTriangular t) =>
      _CompatiblePreviewItem._(triangular: t);

  factory _CompatiblePreviewItem.ciclo(CicloNWay c) =>
      _CompatiblePreviewItem._(ciclo: c);
}
