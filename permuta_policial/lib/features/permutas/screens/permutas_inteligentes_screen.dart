import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_router.dart';
import '../../../core/config/app_styles.dart';
import '../../../core/services/analytics_service.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../profile/widgets/gerir_intencoes_modal.dart';
import '../providers/permutas_inteligentes_provider.dart';
import '../widgets/permuta_inteligente_theme.dart';
import '../widgets/resultados_permuta_inteligente_widget.dart';
import '../../../shared/widgets/app_bar_helper.dart';

class PermutasInteligentesScreen extends StatefulWidget {
  const PermutasInteligentesScreen({super.key});

  @override
  State<PermutasInteligentesScreen> createState() =>
      _PermutasInteligentesScreenState();
}

class _PermutasInteligentesScreenState extends State<PermutasInteligentesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackPageView();
      final dash = Provider.of<DashboardProvider>(context, listen: false);
      if (dash.userData == null) {
        dash.fetchInitialData();
      }
      Provider.of<PermutasInteligentesProvider>(context, listen: false)
          .fetchMatches();
    });
  }

  Future<void> _trackPageView() async {
    try {
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      await analytics.trackPageView('/permutas-inteligentes');
    } catch (e) {
      debugPrint('Erro ao rastrear page view: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: PermutaInteligenteTheme.bgDeep,
        colorScheme: const ColorScheme.dark(
          primary: PermutaInteligenteTheme.accentCyan,
          secondary: PermutaInteligenteTheme.accentPurple,
          surface: PermutaInteligenteTheme.bgPanel,
        ),
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          context.pop();
        },
        child: Scaffold(
          backgroundColor: PermutaInteligenteTheme.bgDeep,
          appBar: AppBar(
            backgroundColor: PermutaInteligenteTheme.bgDeep,
            foregroundColor: PermutaInteligenteTheme.textPrimary,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        PermutaInteligenteTheme.accentPurple.withValues(alpha: 0.4),
                        PermutaInteligenteTheme.accentCyan.withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.hub, size: 20, color: PermutaInteligenteTheme.accentCyan),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Permutas Inteligentes', style: PermutaInteligenteTheme.titleStyle(15)),
                    Text('Motor Gráfico · BETA', style: PermutaInteligenteTheme.monoStyle(9)),
                  ],
                ),
              ],
            ),
            actions: [
              Consumer<PermutasInteligentesProvider>(
                builder: (context, pi, _) {
                  return IconButton(
                    tooltip: 'Recalcular grafo',
                    onPressed: pi.isLoading ? null : () => pi.fetchMatches(refresh: true),
                    icon: pi.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, color: PermutaInteligenteTheme.accentCyan),
                  );
                },
              ),
              ...AppBarHelper.adicionarBotaoRelatarProblema(context),
            ],
          ),
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  PermutaInteligenteTheme.bgDeep,
                  PermutaInteligenteTheme.bgPanel.withValues(alpha: 0.4),
                  PermutaInteligenteTheme.bgDeep,
                ],
              ),
            ),
            child: Consumer2<DashboardProvider, PermutasInteligentesProvider>(
              builder: (context, dash, pi, _) {
                if (dash.isLoadingInitialData && dash.userData == null) {
                  return _loadingState('Inicializando motor...');
                }

                final perfilIncompleto = dash.userData?.unidadeAtualNome == null &&
                    dash.userData?.municipioAtualNome == null;

                return RefreshIndicator(
                  color: PermutaInteligenteTheme.accentCyan,
                  backgroundColor: PermutaInteligenteTheme.bgPanel,
                  onRefresh: () => pi.fetchMatches(refresh: true),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (perfilIncompleto)
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverToBoxAdapter(child: _buildPerfilIncompleto()),
                        ),
                      if (!perfilIncompleto)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          sliver: SliverToBoxAdapter(
                            child: _buildIntencoesCompact(dash),
                          ),
                        ),
                      if (!perfilIncompleto)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: _buildResultsSliver(pi, dash),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerfilIncompleto() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: PermutaInteligenteTheme.panelDecoration(
        borderColor: PermutaInteligenteTheme.accentAmber,
      ),
      child: Column(
        children: [
          const Icon(Icons.sensors_off, color: PermutaInteligenteTheme.accentAmber, size: 40),
          const SizedBox(height: 12),
          Text('Perfil incompleto', style: PermutaInteligenteTheme.titleStyle(16)),
          const SizedBox(height: 8),
          Text(
            'Defina sua lotação para o grafo neural mapear suas permutas.',
            textAlign: TextAlign.center,
            style: PermutaInteligenteTheme.monoStyle(11),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.completarPerfil),
            icon: const Icon(Icons.edit_location_alt),
            label: const Text('Completar Perfil'),
            style: FilledButton.styleFrom(backgroundColor: PermutaInteligenteTheme.accentPurple),
          ),
        ],
      ),
    );
  }

  Widget _buildIntencoesCompact(DashboardProvider dash) {
    final count = dash.intencoes.length;
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => ChangeNotifierProvider.value(
            value: dash,
            child: const GerirIntencoesModal(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: PermutaInteligenteTheme.glassCard(accent: PermutaInteligenteTheme.accentPurple),
        child: Row(
          children: [
            const Icon(Icons.tune, color: PermutaInteligenteTheme.accentPurple, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count intenção(ões) ativas', style: PermutaInteligenteTheme.titleStyle(12)),
                  Text('Toque para editar vetores de destino', style: PermutaInteligenteTheme.monoStyle(10)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: PermutaInteligenteTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _loadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: PermutaInteligenteTheme.accentCyan,
            ),
          ),
          const SizedBox(height: 16),
          Text(message, style: PermutaInteligenteTheme.monoStyle(12)),
        ],
      ),
    );
  }

  Widget _buildResultsSliver(PermutasInteligentesProvider pi, DashboardProvider dash) {
    if (pi.isLoading && pi.results == null) {
      return SliverToBoxAdapter(child: _loadingState('Mapeando grafo de permutas...'));
    }

    if (pi.error != null) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: PermutaInteligenteTheme.panelDecoration(
            borderColor: Colors.red.shade300,
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              AppStyles.spacingSmall,
              Text(pi.error!, textAlign: TextAlign.center, style: PermutaInteligenteTheme.monoStyle(11)),
              AppStyles.spacingMedium,
              FilledButton(
                onPressed: () => pi.fetchMatches(refresh: true),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final results = pi.results;
    if (results == null) {
      return SliverToBoxAdapter(
        child: FilledButton(
          onPressed: () => pi.fetchMatches(),
          child: const Text('Ativar motor'),
        ),
      );
    }

    if (results.totalMatches == 0) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: PermutaInteligenteTheme.panelDecoration(),
          child: Column(
            children: [
              Icon(Icons.blur_on, size: 56, color: PermutaInteligenteTheme.accentPurple.withValues(alpha: 0.5)),
              const SizedBox(height: 14),
              Text('Grafo vazio', style: PermutaInteligenteTheme.titleStyle(18)),
              const SizedBox(height: 8),
              Text(
                'Nenhuma aresta compatível encontrada. Amplie o raio nas intenções ou aguarde novos policiais na rede.',
                textAlign: TextAlign.center,
                style: PermutaInteligenteTheme.monoStyle(11),
              ),
            ],
          ),
        ),
      );
    }

    final user = dash.userData;
    final location = [
      user?.municipioAtualNome,
      user?.estadoAtualSigla,
    ].whereType<String>().where((s) => s.isNotEmpty).join('-');

    return SliverToBoxAdapter(
      child: ResultadosPermutaInteligenteWidget(
        results: results,
        userName: user?.nome,
        userLocation: location.isEmpty ? null : location,
      ),
    );
  }
}
