// /lib/features/dashboard/screens/dashboard_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/dashboard_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_router.dart';
import '../../../core/config/app_theme.dart';
import '../../../core/services/analytics_service.dart';

// Widgets filhos
import '../widgets/boas_vindas_card.dart';
import '../widgets/admin_forum_buttons.dart';
import '../widgets/parceiros_card.dart';
import '../../consultoria_juridica/widgets/consultoria_juridica_section.dart';
import '../../../core/models/parceiro.dart';
import '../../notificacoes/providers/notificacoes_provider.dart';
import '../../notificacoes/widgets/atualizacao_dialog.dart';
import '../../chat/providers/chat_provider.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../../core/services/socket_service.dart';
import '../../marketplace/providers/marketplace_provider.dart';
import '../../marketplace/screens/marketplace_photo_picker_screen.dart';
import '../../../core/services/atualizacao_service.dart';
import '../../permutas/providers/permutas_inteligentes_provider.dart';
import '../../forum/screens/forum_list_screen.dart';

// Modais
import '../widgets/minesweeper_game.dart';
import '../widgets/dashboard_onboarding.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime? _lastBackPressTime;
  final ScrollController _scrollController = ScrollController();
  bool _postLoadActionsDone = false;
  DashboardProvider? _dashboardProvider;

  @override
  void dispose() {
    _dashboardProvider?.removeListener(_onDashboardProviderChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackPageView();
      _dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      _dashboardProvider!.addListener(_onDashboardProviderChanged);
      _dashboardProvider!.fetchInitialData();
      Provider.of<PermutasInteligentesProvider>(context, listen: false).fetchSummary();
      // Carrega notificações e atualiza contador
      final notifProvider = Provider.of<NotificacoesProvider>(context, listen: false);
      notifProvider.loadNotificacoes();
      notifProvider.bindSocketRefresh(Provider.of<SocketService>(context, listen: false));
      // Carrega mensagens não lidas do chat
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.initializeSocket();
      chatProvider.loadMensagensNaoLidas();
      // Carrega contagem de anúncios pendentes se for admin
      if ((_dashboardProvider!.userData?.isEmbaixador ?? false) ||
          (_dashboardProvider!.userData?.isModerator ?? false)) {
        final marketplaceProvider = Provider.of<MarketplaceProvider>(context, listen: false);
        marketplaceProvider.loadPendentesCount();
      }

      if (!_dashboardProvider!.isLoadingInitialData) {
        _onDashboardProviderChanged();
      }
    });
  }

  void _onDashboardProviderChanged() {
    final provider = _dashboardProvider;
    if (provider == null || provider.isLoadingInitialData || _postLoadActionsDone) return;
    _postLoadActionsDone = true;
    provider.removeListener(_onDashboardProviderChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPostLoadActions());
  }

  Future<void> _runPostLoadActions() async {
    if (!mounted) return;
    try {
      await DashboardOnboarding.showIfNeeded(context);
      if (!mounted) return;
      await _scrollToBottom();
      if (!mounted) return;
      await _verificarAtualizacao();
    } catch (e) {
      debugPrint('⚠️ Dashboard pós-carregamento: $e');
    }
  }

  Future<void> _scrollToBottom() async {
    if (!mounted) return;
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    if (isDesktop) return;

    for (var attempt = 0; attempt < 5; attempt++) {
      await Future.delayed(Duration(milliseconds: 80 + attempt * 60));
      if (!mounted || !_scrollController.hasClients) continue;
      final target = _scrollController.position.maxScrollExtent;
      if (target <= 0) continue;
      try {
        await _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
        if (!mounted || !_scrollController.hasClients) return;
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      } catch (e) {
        debugPrint('⚠️ Scroll dashboard: $e');
      }
      return;
    }
  }
  
  Future<void> _verificarAtualizacao() async {
    try {
      final atualizacaoService = Provider.of<AtualizacaoService>(context, listen: false);
      final nota = await atualizacaoService.verificarNovaAtualizacao();
      
      if (nota != null && mounted) {
        final versao = await atualizacaoService.obterVersaoAtual();
        if (versao != null && mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AtualizacaoDialog(nota: nota, versao: versao),
          );
        }
      }
    } catch (e) {
      // Ignora erros silenciosamente
      debugPrint('Erro ao verificar atualização: $e');
    }
  }

  Future<void> _trackPageView() async {
    try {
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      await analyticsService.trackPageView('/dashboard');
    } catch (e) {
      debugPrint('Erro ao rastrear page view do dashboard: $e');
    }
  }

  
  Future<void> _logout() async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    await provider.logout();
    if (mounted) {
      context.go(AppRoutes.auth);
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o link.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final now = DateTime.now();
        final shouldExit = _lastBackPressTime != null &&
            now.difference(_lastBackPressTime!) < const Duration(seconds: 2);
        
        if (shouldExit) {
          // Permite sair do app
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          // Mostra mensagem e registra o tempo
          _lastBackPressTime = now;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pressione voltar novamente para sair'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Consumer2<DashboardProvider, NotificacoesProvider>(
        builder: (context, provider, notificacoesProvider, child) {
          final isDesktop = MediaQuery.of(context).size.width >= 800;
          return Scaffold(
            appBar: _buildAppBar(
              context,
              provider,
              notificacoesProvider,
              showNavActions: !isDesktop,
            ),
            body: _buildBody(context, provider, isDesktop: isDesktop),
            floatingActionButton: isDesktop
                ? null
                : _buildFloatingActionButton(context, provider),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    DashboardProvider provider,
    NotificacoesProvider notificacoesProvider, {
    bool showNavActions = true,
  }) {
    final theme = Theme.of(context);
    
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Image.asset(
            'images/ic_launcher.png',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.shield, color: theme.primaryColor, size: 24);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Permuta Policial',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      actions: showNavActions
          ? [
              IconButton(
                icon: Icon(Icons.person_outline, color: theme.iconTheme.color),
                tooltip: 'Meus Dados',
                onPressed: () {
                  context.push(AppRoutes.meusDados);
                },
              ),
              Consumer<NotificacoesProvider>(
                builder: (context, notifProvider, child) {
                  return Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications_outlined, color: theme.iconTheme.color),
                        tooltip: 'Notificações',
                        onPressed: () {
                          context.push(AppRoutes.notificacoes);
                        },
                      ),
                      if (notifProvider.countNaoLidas > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              notifProvider.countNaoLidas > 9 ? '9+' : '${notifProvider.countNaoLidas}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.help_outline, color: theme.iconTheme.color),
                tooltip: 'Ajuda',
                onPressed: () => _launchURL('https://br.permutapolicial.com.br/help.html'),
              ),
              IconButton(
                icon: Icon(Icons.logout, color: theme.iconTheme.color),
                tooltip: 'Sair',
                onPressed: _logout,
              ),
            ]
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    DashboardProvider provider, {
    bool isDesktop = false,
  }) {
    if (provider.isLoadingInitialData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.initialDataError != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Erro ao carregar dados', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(provider.initialDataError!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => provider.fetchInitialData(),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
      ));
    }
    if (provider.userData == null) {
      return const Center(child: Text('Não foi possível carregar os dados do usuário.'));
    }
    if (isDesktop) {
      return _buildDesktopLayout(provider);
    }
    return _buildMobileLayout(provider);
  }


  Widget _buildGestaoCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0, // Cards quadrados
      children: [
        _buildGestorHorasCard(),
        _buildSistemaQuestoesCard(),
      ],
    );
  }

  Widget _buildGestorHorasCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: () => context.push(AppRoutes.calendar),
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.access_time, color: theme.primaryColor, size: 24),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Gestor de Horas e Soldo',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gerencie suas escalas, etapas e soldo',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSistemaQuestoesCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: () => context.push(AppRoutes.questions),
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.quiz,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Questões & Simulados',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pratique e faça simulados',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditaisTransferenciaCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: () => context.push(AppRoutes.editaisHub),
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 1, 105, 190).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: Color.fromARGB(255, 1, 105, 190),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Editais de Transferência',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Acompanhe editais e transferências',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermutasInteligentesCard(
    PermutasInteligentesProvider piProvider, {
    bool expanded = false,
  }) {
    final theme = Theme.of(context);
    final count = piProvider.summaryCount;
    final countLabel = piProvider.isLoadingSummary
        ? 'Calculando matches...'
        : count != null
            ? '$count matches (motor gráfico)'
            : 'Motor gráfico experimental — em desenvolvimento';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.deepPurple.shade100),
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.permutasInteligentes),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(expanded ? 20 : 12),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(expanded ? 16 : 8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withAlpha(26),
                  borderRadius: BorderRadius.circular(expanded ? 12 : 8),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.deepPurple.shade700,
                  size: expanded ? 32 : 24,
                ),
              ),
              SizedBox(width: expanded ? 20 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Permutas Inteligentes — Experimental',
                            style: (expanded
                                    ? theme.textTheme.titleLarge
                                    : theme.textTheme.titleMedium)
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: expanded ? null : 14,
                            ),
                          ),
                        ),
                        Chip(
                          label: const Text('BETA', style: TextStyle(fontSize: 10)),
                          backgroundColor: Colors.deepPurple.shade50,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      countLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: expanded ? null : 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mapa neural interativo · ciclos N-way · score heurístico',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.deepPurple.shade400,
                        fontSize: expanded ? 12 : 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: expanded ? 20 : 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapaTaticoCard() {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => context.push(AppRoutes.mapaTatico),
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: AppTheme.primaryLight,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Mapa Tático — Experimental',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Chip(
                            label: const Text('BETA', style: TextStyle(fontSize: 10)),
                            backgroundColor: Colors.deepPurple.shade50,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Grupos, pontos e recursos',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _chavePix = '0938edff-bb0b-4a97-b8c5-3591cbf4d621';

  Widget _buildApoiePixCard() {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: InkWell(
        onTap: () => _copiarChavePix(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.green.shade50,
                Colors.green.shade100.withAlpha(80),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.volunteer_activism,
                  color: Colors.green.shade800,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apoie o projeto — PIX',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toque para copiar a chave PIX e ajudar a manter a plataforma',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.copy, color: Colors.green.shade700),
            ],
          ),
        ),
      ),
    );
  }

  // Layout Mobile com nova ordem
  Widget _buildMobileLayout(DashboardProvider provider) {
    // Perfil está completo se tiver unidade OU município definido
    final perfilIncompleto = provider.userData?.unidadeAtualNome == null && 
                             provider.userData?.municipioAtualNome == null;
    final nome = provider.userData?.nome ?? 'Usuário';
    
    return RefreshIndicator(
      onRefresh: () async {
        await provider.fetchInitialData();
        // Atualiza contador de notificações
        Provider.of<NotificacoesProvider>(context, listen: false).refreshCount();
      },
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        children: [
          // Hero / Boas-Vindas (sempre visível)
          BoasVindasCard(
            nome: nome,
            perfilIncompleto: perfilIncompleto,
            onCompletarPerfil: perfilIncompleto 
              ? () => context.push(AppRoutes.completarPerfil)
              : null,
          ),
          const SizedBox(height: 12),
          
          _buildApoiePixCard(),
          const SizedBox(height: 12),
          
          // Grid de Cards Prioritários (2 colunas)
          _buildGridCards(provider),
          const SizedBox(height: 12),
          
          // Card Parceiros (carrossel) - sempre exibe
          ParceirosCard(parceiros: provider.parceiros.map((p) => Parceiro.fromJson(p)).toList()),
          const SizedBox(height: 12),

          ConsultoriaJuridicaSection(advogados: provider.consultoriaAdvogados),
          if (provider.consultoriaAdvogados.isNotEmpty) const SizedBox(height: 12),
          
          // Cards de Gestão
          _buildGestaoCards(),
          const SizedBox(height: 12),
          
          // Cards "Editais de Transferência" e "Marketplace"
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              _buildEditaisTransferenciaCard(),
              _buildCompactCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Marketplace',
                description: 'Anúncios e vendas',
                color: const Color.fromARGB(255, 1, 105, 190),
                onTap: () => context.push(AppRoutes.marketplace),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 9º card — motor experimental (isolado do Ambiente de Permutas)
          Consumer<PermutasInteligentesProvider>(
            builder: (context, piProvider, _) => _buildPermutasInteligentesCard(piProvider),
          ),
          const SizedBox(height: 12),
          
          if (provider.userData != null)
            AdminForumButtons(
              isEmbaixador: provider.userData!.isEmbaixador,
              isModerator: provider.userData!.isModerator,
            ),
          if (provider.userData != null) const SizedBox(height: 16),
          
          // Botão do Campo Minado
          _buildCampoMinadoCard(),
          const SizedBox(height: 12),
          
        ],
      ),
    );
  }

  Widget _buildGridCards(DashboardProvider provider) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0, // Cards quadrados para design consistente
      children: [
        _buildCompactCard(
          icon: Icons.swap_horiz,
          title: 'Ambiente de Permutas',
          description: '${(provider.matches?.diretas.length ?? 0) + (provider.matches?.proximas.length ?? 0) + (provider.matches?.interessados.length ?? 0) + (provider.matches?.triangulares.length ?? 0) + (provider.matches?.triangularesProximas.length ?? 0)} matches encontrados',
          color: const Color.fromARGB(255, 1, 105, 190),
          onTap: () => context.push(AppRoutes.permutas),
        ),
        _buildCompactCard(
          icon: Icons.chat_bubble_outline,
          title: 'Mensagens',
          description: 'Chat com outros usuários',
          color: const Color.fromARGB(255, 1, 105, 190),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ChatListScreen(),
              ),
            );
          },
        ),
        _buildCompactCard(
          icon: Icons.map_outlined,
          title: 'Mapa',
          description: 'Visualize permutas no mapa',
          color: const Color.fromARGB(255, 1, 105, 190),
          onTap: () => context.push(AppRoutes.mapa),
        ),
        _buildMapaTaticoCard(),
      ],
    );
  }

  Widget _buildCompactCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(DashboardProvider provider) {
    final perfilIncompleto = provider.userData?.unidadeAtualNome == null &&
        provider.userData?.municipioAtualNome == null;
    final nome = provider.userData?.nome ?? 'Usuário';
    final matchCount = (provider.matches?.diretas.length ?? 0) +
        (provider.matches?.proximas.length ?? 0) +
        (provider.matches?.interessados.length ?? 0) +
        (provider.matches?.triangulares.length ?? 0) +
        (provider.matches?.triangularesProximas.length ?? 0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDesktopSidebar(provider),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BoasVindasCard(
                  nome: nome,
                  perfilIncompleto: perfilIncompleto,
                  compact: true,
                  onCompletarPerfil: perfilIncompleto
                      ? () => context.push(AppRoutes.completarPerfil)
                      : null,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildDesktopColumn([
                          () => _buildDesktopModuleCard(
                                icon: Icons.swap_horiz,
                                title: 'Ambiente de Permutas',
                                subtitle: '$matchCount matches encontrados',
                                color: const Color.fromARGB(255, 1, 105, 190),
                                onTap: () => context.push(AppRoutes.permutas),
                              ),
                          () => _buildDesktopModuleCard(
                                icon: Icons.chat_bubble_outline,
                                title: 'Mensagens',
                                subtitle: 'Chat com outros usuários',
                                color: const Color.fromARGB(255, 1, 105, 190),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ChatListScreen(),
                                    ),
                                  );
                                },
                              ),
                          () => _buildDesktopModuleCard(
                                icon: Icons.map_outlined,
                                title: 'Mapa de Permutas',
                                subtitle: 'Visualize permutas no mapa',
                                color: const Color.fromARGB(255, 1, 105, 190),
                                onTap: () => context.push(AppRoutes.mapa),
                              ),
                          () => _buildDesktopModuleCard(
                                icon: Icons.layers_outlined,
                                title: 'Mapa Tático',
                                subtitle: 'Experimental (BETA)',
                                color: AppTheme.primaryLight,
                                badge: 'BETA',
                                onTap: () => context.push(AppRoutes.mapaTatico),
                              ),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDesktopColumn([
                          () => _buildDesktopModuleCard(
                                icon: Icons.access_time,
                                title: 'Gestor de Horas e Soldo',
                                subtitle: 'Escalas, etapas e soldo',
                                color: Theme.of(context).primaryColor,
                                onTap: () => context.push(AppRoutes.calendar),
                              ),
                          () => _buildDesktopModuleCard(
                                icon: Icons.quiz,
                                title: 'Questões & Simulados',
                                subtitle: 'Pratique e faça simulados',
                                color: Colors.blue,
                                onTap: () => context.push(AppRoutes.questions),
                              ),
                          () => _buildDesktopModuleCard(
                                icon: Icons.description_outlined,
                                title: 'Editais de Transferência',
                                subtitle: 'Acompanhe editais',
                                color: const Color.fromARGB(255, 1, 105, 190),
                                onTap: () => context.push(AppRoutes.editaisHub),
                              ),
                          () => _buildDesktopModuleCard(
                                icon: Icons.shopping_bag_outlined,
                                title: 'Marketplace',
                                subtitle: 'Anúncios e vendas',
                                color: const Color.fromARGB(255, 1, 105, 190),
                                onTap: () => context.push(AppRoutes.marketplace),
                              ),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Consumer<PermutasInteligentesProvider>(
                                builder: (context, piProvider, _) {
                                  return _buildDesktopModuleCard(
                                    icon: Icons.auto_awesome,
                                    title: 'Permutas Inteligentes',
                                    subtitle: piProvider.isLoadingSummary
                                        ? 'Calculando matches...'
                                        : piProvider.summaryCount != null
                                            ? '${piProvider.summaryCount} matches (motor gráfico)'
                                            : 'Motor gráfico experimental',
                                    color: Colors.deepPurple.shade700,
                                    badge: 'BETA',
                                    onTap: () => context.push(AppRoutes.permutasInteligentes),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: _buildDesktopModuleCard(
                                icon: Icons.forum_outlined,
                                title: 'Fórum',
                                subtitle: 'Comunidade de agentes',
                                color: Theme.of(context).primaryColor,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ForumListScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              flex: 2,
                              child: ParceirosCard(
                                compact: true,
                                parceiros: provider.parceiros
                                    .map((p) => Parceiro.fromJson(p))
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: _buildCampoMinadoCard(compact: true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (provider.consultoriaAdvogados.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ConsultoriaJuridicaSection(advogados: provider.consultoriaAdvogados),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSidebar(DashboardProvider provider) {
    final theme = Theme.of(context);
    final isAdmin = provider.userData?.isEmbaixador == true ||
        provider.userData?.isModerator == true;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          right: BorderSide(color: theme.dividerColor.withAlpha(80)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildSidebarNavItem(
            icon: Icons.person_outline,
            label: 'Meus Dados',
            onTap: () => context.push(AppRoutes.meusDados),
          ),
          Consumer<NotificacoesProvider>(
            builder: (context, notifProvider, _) {
              return _buildSidebarNavItem(
                icon: Icons.notifications_outlined,
                label: 'Notificações',
                badge: notifProvider.countNaoLidas,
                onTap: () => context.push(AppRoutes.notificacoes),
              );
            },
          ),
          _buildSidebarNavItem(
            icon: Icons.help_outline,
            label: 'Ajuda',
            onTap: () => _launchURL('https://br.permutapolicial.com.br/help.html'),
          ),
          if (isAdmin)
            _buildSidebarNavItem(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Administração',
              onTap: () => context.push(AppRoutes.admin),
            ),
          _buildSidebarNavItem(
            icon: Icons.logout,
            label: 'Sair',
            onTap: _logout,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildApoiePixSidebarButton(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 22, color: theme.iconTheme.color),
                  if (badge > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          badge > 9 ? '9+' : '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApoiePixSidebarButton() {
    return Material(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _copiarChavePix(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.volunteer_activism, color: Colors.green.shade800, size: 22),
              const SizedBox(height: 8),
              Text(
                'Apoie o projeto',
                style: TextStyle(
                  color: Colors.green.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Copiar chave PIX',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopColumn(List<Widget Function()> cardBuilders) {
    return Column(
      children: [
        for (var i = 0; i < cardBuilders.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Expanded(child: cardBuilders[i]()),
        ],
      ],
    );
  }

  Widget _buildDesktopModuleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampoMinadoCard({bool compact = false}) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MinesweeperGame(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 10 : 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.casino,
                  color: Colors.orange,
                  size: compact ? 22 : 24,
                ),
              ),
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Campo Minado',
                      style: (compact
                              ? Theme.of(context).textTheme.titleSmall
                              : Theme.of(context).textTheme.titleMedium)
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Jogue um clássico jogo de campo minado',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: compact ? 11 : null,
                          ),
                      maxLines: compact ? 2 : null,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: compact ? 14 : 16),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildFloatingActionButton(BuildContext context, DashboardProvider provider) {
    return FloatingActionButton(
      onPressed: () => _showActionMenu(context, provider),
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.add),
    );
  }

  void _showActionMenu(BuildContext context, DashboardProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildActionMenuItem(
              context,
              icon: Icons.share,
              title: 'Compartilhe nosso aplicativo com um colega',
              onTap: () {
                context.pop(ctx);
                _copiarTexto(
                  context,
                  'Conheça o projeto criado para facilitar permutas e negociações entre agentes de segurança pública https://permutapolicial.com.br',
                );
              },
            ),
            const Divider(height: 32),
            _buildActionMenuItem(
              context,
              icon: Icons.account_balance_wallet,
              title: 'Apoie o projeto - PIX',
              onTap: () {
                context.pop(ctx);
                _copiarChavePix(context);
              },
            ),
            const Divider(height: 32),
            _buildActionMenuItem(
              context,
              icon: Icons.add_photo_alternate,
              title: 'Criar anúncio',
              onTap: () {
                context.pop(ctx);
                _navegarParaCriarAnuncio(context, provider);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _copiarTexto(BuildContext context, String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Texto copiado para a área de transferência!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copiarChavePix(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: _chavePix));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chave PIX copiada com sucesso, obrigado pelo apoio!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navegarParaCriarAnuncio(BuildContext context, DashboardProvider provider) async {
    final user = provider.userData;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa estar logado para criar anúncios'),
        ),
      );
      return;
    }
    
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MarketplacePhotoPickerScreen(),
      ),
    );
    
    if (result == true && mounted) {
      // Recarrega dados se necessário
      provider.fetchInitialData();
    }
  }
}

// Função de preview para o Flutter Widget Preview
Widget previewDashboardScreen() {
  return MaterialApp(
    theme: ThemeData.light(),
    home: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.shield, color: ThemeData.light().primaryColor, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Permuta Policial',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Meus Dados',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notificações',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Ajuda',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Boas Vindas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.waving_hand, color: Colors.amber[700], size: 32),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bem-vindo!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Nome do Usuário',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Cards de Ação
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: [
                _buildMockCard(
                  icon: Icons.access_time,
                  title: 'Gestor de Horas e Soldo',
                  subtitle: 'Gerencie suas escalas',
                  color: Colors.blue,
                ),
                _buildMockCard(
                  icon: Icons.quiz,
                  title: 'Sistema de Questões',
                  subtitle: 'Simulados e provas',
                  color: Colors.purple,
                ),
                _buildMockCard(
                  icon: Icons.map,
                  title: 'Mapa de Exploração',
                  subtitle: 'Explore oportunidades',
                  color: Colors.green,
                ),
                _buildMockCard(
                  icon: Icons.store,
                  title: 'Marketplace',
                  subtitle: 'Compre e venda',
                  color: Colors.orange,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Seção de Ações Rápidas
            const Text(
              'Ações Rápidas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.search),
                      title: const Text('Procurar Permutas'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: const Text('Criar Permuta'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Card de Parceiros (mock)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.handshake, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Nossos Parceiros',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Logos dos parceiros',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Nova Permuta'),
      ),
    ),
  );
}

// Helper para criar cards mock
Widget _buildMockCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
}) {
  return Card(
    child: InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}