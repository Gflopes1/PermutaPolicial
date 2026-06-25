// /lib/features/permutas/screens/permutas_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_router.dart';
import '../../../core/config/app_styles.dart';
import '../../../core/config/app_theme.dart';
import '../../../core/services/analytics_service.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/minhas_intencoes_card.dart';
import '../../dashboard/widgets/resultados_permuta_widget.dart';
import '../../profile/widgets/gerir_intencoes_modal.dart';
import '../../../shared/widgets/app_bar_helper.dart';

class PermutasScreen extends StatefulWidget {
  final int initialTabIndex;

  const PermutasScreen({super.key, this.initialTabIndex = 0});

  @override
  State<PermutasScreen> createState() => _PermutasScreenState();
}

class _PermutasScreenState extends State<PermutasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackPageView();
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      if (provider.userData == null) {
        provider.fetchInitialData();
      } else if (provider.matches == null && !provider.isLoadingMatches) {
        provider.fetchMatches();
      }
    });
  }

  Future<void> _trackPageView() async {
    try {
      final analyticsService =
          Provider.of<AnalyticsService>(context, listen: false);
      await analyticsService.trackPageView('/permutas');
    } catch (e) {
      debugPrint('Erro ao rastrear page view de permutas: $e');
    }
  }

  Future<void> _onRefresh(DashboardProvider provider) async {
    await provider.refreshPermutasData();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.card,
          elevation: 0,
          title: Text('Ambiente de Permutas', style: AppStyles.titleMedium),
          actions: [
            ...AppBarHelper.adicionarBotaoRelatarProblema(context),
          ],
        ),
        body: Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            if (provider.isLoadingInitialData && provider.userData == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.initialDataError != null && provider.userData == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: AppTheme.error),
                      AppStyles.spacingSmall,
                      Text('Erro ao carregar dados',
                          style: AppStyles.titleMedium),
                      AppStyles.spacingSmall,
                      Text(provider.initialDataError!,
                          style: AppStyles.bodyMedium,
                          textAlign: TextAlign.center),
                      AppStyles.spacingMedium,
                      ElevatedButton(
                        style: AppStyles.primaryButton,
                        onPressed: () => provider.fetchInitialData(),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final perfilIncompleto =
                provider.userData?.unidadeAtualNome == null &&
                    provider.userData?.municipioAtualNome == null;

            return RefreshIndicator(
              onRefresh: () => _onRefresh(provider),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (perfilIncompleto) ...[
                          Card(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withAlpha(26),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  const Icon(Icons.info_outline,
                                      color: Colors.orange, size: 40),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Complete seu perfil',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Para ver suas combinações de permuta, defina sua lotação atual.',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () =>
                                        context.push(AppRoutes.completarPerfil),
                                    icon: const Icon(Icons.edit_location_alt),
                                    label: const Text('Completar Perfil'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        MinhasIntencoesCard(
                          intencoes: provider.intencoes,
                          onRenew: provider.renewIntencoes,
                          onPermutaConcluida: provider.markPermutaConcluida,
                          onEdit: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => ChangeNotifierProvider.value(
                                value: provider,
                                child: const GerirIntencoesModal(),
                              ),
                            );
                          },
                        ),
                      ]),
                    ),
                  ),
                  if (!perfilIncompleto)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: _buildMatchesSliver(provider),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _surfaceBox({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildMatchesSliver(DashboardProvider provider) {
    if (provider.isLoadingMatches && provider.matches == null) {
      return SliverToBoxAdapter(
        child: _surfaceBox(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 2),
                SizedBox(height: 16),
                Text('Buscando combinações...', style: AppStyles.bodyMedium),
              ],
            ),
          ),
        ),
        ),
      );
    }

    if (provider.matchesError != null) {
      return SliverToBoxAdapter(
        child: _surfaceBox(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Erro ao carregar combinações', style: AppStyles.titleMedium),
                const SizedBox(height: 8),
                Text(provider.matchesError!, style: AppStyles.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchMatches(),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (provider.matches == null) {
      return SliverToBoxAdapter(
        child: _surfaceBox(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade600),
                const SizedBox(height: 16),
                Text('Não foi possível carregar as combinações', style: AppStyles.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchMatches(),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final matches = provider.matches!;
    final totalMatches = matches.diretas.length +
        matches.proximas.length +
        matches.interessados.length +
        matches.triangulares.length +
        matches.triangularesProximas.length;

    if (totalMatches == 0) {
      return SliverToBoxAdapter(
        child: _surfaceBox(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 56, color: Colors.grey.shade600),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma combinação encontrada',
                  style: AppStyles.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Adicione intenções para encontrar combinações.',
                  style: AppStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: ResultadosPermutaWidget(
        results: matches,
        initialTabIndex: widget.initialTabIndex,
      ),
    );
  }
}
