import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/app_router.dart';
import '../../../core/models/match_results.dart';
import '../../../core/models/smart_match_results.dart';
import '../../../core/services/analytics_service.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../notificacoes/providers/notificacoes_provider.dart';
import '../../profile/widgets/gerir_intencoes_modal.dart';
import '../models/match_tipo.dart';
import '../providers/permutas_inteligentes_provider.dart';
import '../utils/permuta_contact_actions.dart';
import '../utils/permutas_unificadas_utils.dart';
import '../widgets/ciclo_nway_card.dart';
import '../widgets/match_card.dart';
import '../widgets/permuta_graph_canvas.dart';
import '../widgets/permuta_graph_model.dart';
import '../widgets/permuta_unificada_theme.dart';
import '../widgets/permutas_lazy_list.dart';
import '../widgets/triangular_match_card.dart';
import '../../../shared/widgets/app_bar_helper.dart';

class PermutasUnificadasScreen extends StatefulWidget {
  final int initialTabIndex;

  const PermutasUnificadasScreen({super.key, this.initialTabIndex = 0});

  @override
  State<PermutasUnificadasScreen> createState() => _PermutasUnificadasScreenState();
}

class _PermutasUnificadasScreenState extends State<PermutasUnificadasScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _interessadosKey = GlobalKey();
  final Set<int> _contatosSolicitados = {};
  bool _motorInteligenteExpanded = false;
  bool _proximidadeExpanded = false;
  bool _interessadosExpanded = false;
  bool _mapaExpanded = false;
  bool _scrolledToInitialTab = false;
  PermutaGraphData? _cachedGraph;
  SmartMatchResults? _cachedGraphSource;
  Set<int>? _cachedPiIds;
  SmartMatchResults? _cachedPiIdsSource;

  @override
  void initState() {
    super.initState();
    _interessadosExpanded = widget.initialTabIndex == 3;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackPageView();
      _initData();
      // Notificações em background — não bloqueia abertura da tela.
      Future.microtask(_carregarContatosSolicitados);
    });
  }

  Future<void> _initData() async {
    final dash = Provider.of<DashboardProvider>(context, listen: false);
    final pi = Provider.of<PermutasInteligentesProvider>(context, listen: false);

    if (dash.userData == null) {
      await dash.fetchInitialData();
    }
    if (!mounted) return;

    // Motor clássico primeiro; PI em paralelo — não bloqueia a abertura da tela.
    dash.fetchMatches();
    pi.fetchMatches();
  }

  Set<int> _piIds(PermutasInteligentesProvider pi) {
    final results = pi.results;
    if (results == null) return const {};
    if (identical(results, _cachedPiIdsSource) && _cachedPiIds != null) {
      return _cachedPiIds!;
    }
    _cachedPiIdsSource = results;
    _cachedPiIds = PermutasUnificadasUtils.piPolicialIds(results);
    return _cachedPiIds!;
  }

  Future<void> _trackPageView() async {
    try {
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      await analytics.trackPageView('/permutas');
    } catch (e) {
      debugPrint('Erro ao rastrear page view: $e');
    }
  }

  Future<void> _carregarContatosSolicitados() async {
    try {
      final notif = Provider.of<NotificacoesProvider>(context, listen: false);
      if (notif.notificacoes.isEmpty) {
        await notif.loadNotificacoes();
      }
      if (!mounted) return;
      setState(() {
        for (final n in notif.notificacoes) {
          if ((n.tipo == 'SOLICITACAO_CONTATO' || n.tipo == 'SOLICITACAO_CONTATO_ACEITA') &&
              n.referenciaId != null) {
            _contatosSolicitados.add(n.referenciaId!);
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _onRefresh() async {
    final dash = Provider.of<DashboardProvider>(context, listen: false);
    final pi = Provider.of<PermutasInteligentesProvider>(context, listen: false);
    await Future.wait([
      dash.refreshPermutasData(),
      pi.fetchMatches(refresh: true),
    ]);
  }

  void _marcarSolicitado(int id) => setState(() => _contatosSolicitados.add(id));

  bool _jaSolicitado(Match match) =>
      match.jaSolicitado || _contatosSolicitados.contains(match.id);

  bool _isAnonimo(Match match) => match.ocultarNoMapa && !match.aceitouCompartilhar;

  String _displayName(Match match) {
    if (_isAnonimo(match)) {
      // Tenta mostrar informação útil mesmo para usuários ocultos
      final partes = <String>[];
      if (match.forcaSigla != null && match.forcaSigla.isNotEmpty) {
        partes.add(match.forcaSigla);
      }
      if (match.municipioAtual != null && match.municipioAtual!.isNotEmpty) {
        partes.add(match.municipioAtual!);
      }
      if (partes.isNotEmpty) {
        return 'Usuário não identificado (${partes.join(' - ')})';
      }
      return 'Usuário não identificado';
    }
    
    if (match.ocultarNoMapa &&
        match.aceitouCompartilhar &&
        match.dadosAceitacao != null) {
      return match.dadosAceitacao!['nome']?.toString() ??
          match.dadosAceitacao!['aceitador_nome']?.toString() ??
          match.nome;
    }
    
    // Fallback: se nome está vazio, tenta construir descrição útil
    if (match.nome.isEmpty) {
      final partes = <String>[];
      if (match.forcaSigla != null && match.forcaSigla.isNotEmpty) {
        partes.add(match.forcaSigla);
      }
      if (match.postoGraduacaoNome != null && match.postoGraduacaoNome!.isNotEmpty) {
        partes.add(match.postoGraduacaoNome!);
      }
      if (match.municipioAtual != null && match.municipioAtual!.isNotEmpty) {
        partes.add(match.municipioAtual!);
      }
      if (partes.isNotEmpty) {
        return partes.join(' - ');
      }
      return 'Policial ${match.id}';
    }
    
    return match.nome;
  }

  bool _isGlobalEmpty(DashboardProvider dash, PermutasInteligentesProvider pi) {
    if (dash.isLoadingMatches || (pi.isLoading && pi.results == null)) return false;
    final original = dash.matches;
    if (original == null && pi.results == null) return false;

    final piIds = pi.results != null ? _piIds(pi) : <int>{};
    final imediatos = PermutasUnificadasUtils.countImediatosMatches(
      original,
      pi.results,
      piIds,
    );
    final proximidade = PermutasUnificadasUtils.countProximidadeMatches(
      original,
      pi.results,
      piIds,
    );
    final interessados = PermutasUnificadasUtils.countInteressadosMatches(
      original,
      pi.results,
      piIds,
    );
    final piMotor = pi.results?.ciclosN.length ?? 0;
    return imediatos == 0 &&
        proximidade == 0 &&
        interessados == 0 &&
        piMotor == 0;
  }

  bool _hasAnyResults(DashboardProvider dash, PermutasInteligentesProvider pi) {
    return !_isGlobalEmpty(dash, pi);
  }

  void _maybeScrollToInitialTab(FullMatchResults? original, SmartMatchResults? pi) {
    if (_scrolledToInitialTab || widget.initialTabIndex != 3) return;
    if (original == null && pi == null) return;

    _scrolledToInitialTab = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _interessadosKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: PermutaUnificadaTheme.screenTheme(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          context.pop();
        },
        child: Scaffold(
          backgroundColor: PermutaUnificadaTheme.bgDeep,
          appBar: AppBar(
            backgroundColor: PermutaUnificadaTheme.bgDeep,
            foregroundColor: PermutaUnificadaTheme.textPrimary,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: PermutaUnificadaTheme.bgGlass,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PermutaUnificadaTheme.border),
                  ),
                  child: const Icon(Icons.swap_horiz,
                      size: 20, color: PermutaUnificadaTheme.accent),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Permutas', style: PermutaUnificadaTheme.titleStyle(15)),
                    Text('Motor clássico + inteligente',
                        style: PermutaUnificadaTheme.monoStyle(9)),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Atualizar',
                onPressed: _onRefresh,
                icon: const Icon(Icons.refresh, color: PermutaUnificadaTheme.accentBlue),
              ),
              ...AppBarHelper.adicionarBotaoRelatarProblema(context),
            ],
          ),
          body: DecoratedBox(
            decoration: const BoxDecoration(color: PermutaUnificadaTheme.bgDeep),
            child: Consumer2<DashboardProvider, PermutasInteligentesProvider>(
              builder: (context, dash, pi, _) {
                if (dash.isLoadingInitialData && dash.userData == null) {
                  return _loadingCenter('Carregando perfil...');
                }

                final perfilIncompleto = dash.userData?.unidadeAtualNome == null &&
                    dash.userData?.municipioAtualNome == null;

                _maybeScrollToInitialTab(dash.matches, pi.results);

                return RefreshIndicator(
                  color: PermutaUnificadaTheme.accentBlue,
                  backgroundColor: PermutaUnificadaTheme.bgPanel,
                  onRefresh: _onRefresh,
                  child: CustomScrollView(
                    controller: _scrollController,
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
                          sliver: SliverToBoxAdapter(child: _buildIntencoesCompact(dash)),
                        ),
                      if (!perfilIncompleto) ...[
                        if (_isGlobalEmpty(dash, pi))
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            sliver: SliverToBoxAdapter(
                              child: _buildEmptyState(dash, pi.results),
                            ),
                          )
                        else ...[
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            sliver: SliverToBoxAdapter(
                              child: _buildImediatosSection(dash, pi),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            sliver: SliverToBoxAdapter(
                              child: _buildMotorInteligenteSection(dash, pi),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            sliver: SliverToBoxAdapter(
                              child: _buildProximidadeSection(dash, pi),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            sliver: SliverToBoxAdapter(
                              child: _buildInteressadosSection(dash, pi),
                            ),
                          ),
                        ],
                      ],
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

  Widget _loadingCenter(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: PermutaUnificadaTheme.accentBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(message, style: PermutaUnificadaTheme.monoStyle(12)),
        ],
      ),
    );
  }

  Widget _buildPerfilIncompleto() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: PermutaUnificadaTheme.panelDecoration(
        borderColor: PermutaUnificadaTheme.accent,
      ),
      child: Column(
        children: [
          const Icon(Icons.sensors_off,
              color: PermutaUnificadaTheme.accent, size: 40),
          const SizedBox(height: 12),
          Text('Perfil incompleto', style: PermutaUnificadaTheme.titleStyle(16)),
          const SizedBox(height: 8),
          Text(
            'Defina sua lotação para encontrar combinações de permuta.',
            textAlign: TextAlign.center,
            style: PermutaUnificadaTheme.monoStyle(11),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.completarPerfil),
            icon: const Icon(Icons.edit_location_alt),
            label: const Text('Completar Perfil'),
            style: FilledButton.styleFrom(
              backgroundColor: PermutaUnificadaTheme.accentBlueDeep,
            ),
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
        decoration: PermutaUnificadaTheme.glassCard(),
        child: Row(
          children: [
            const Icon(Icons.tune, color: PermutaUnificadaTheme.accentBlue, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count intenção(ões) ativas',
                      style: PermutaUnificadaTheme.titleStyle(12)),
                  Text('Toque para editar destinos desejados',
                      style: PermutaUnificadaTheme.monoStyle(10)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: PermutaUnificadaTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildImediatosSection(DashboardProvider dash, PermutasInteligentesProvider pi) {
    final piIds = _piIds(pi);
    final count = PermutasUnificadasUtils.countImediatosMatches(
      dash.matches,
      pi.results,
      piIds,
    );

    return _sectionCard(
      icon: Icons.bolt,
      iconColor: PermutaUnificadaTheme.accent,
      title: 'Matches Imediatos',
      subtitle: 'Diretas e triangulares — motor clássico e inteligente',
      badge: count > 0 ? '$count' : null,
      initiallyExpanded: true,
      child: _buildImediatosContent(
        dash,
        pi,
        piIds,
        piStillLoading: pi.isLoading && pi.results == null,
      ),
    );
  }

  Widget _buildImediatosContent(
    DashboardProvider dash,
    PermutasInteligentesProvider pi,
    Set<int> piIds, {
    required bool piStillLoading,
  }) {
    if ((dash.isLoadingMatches && dash.matches == null) ||
        (piStillLoading && pi.results == null && dash.matches == null)) {
      return _shimmerList(3);
    }

    if (dash.matchesError != null) {
      return _errorBox(
        dash.matchesError!,
        onRetry: () => dash.fetchMatches(),
      );
    }

    final original = dash.matches;
    final piResults = pi.results;
    final piExactTri = piResults != null
        ? PermutasUnificadasUtils.piTriangularesExatas(piResults)
        : const <MatchTriangular>[];

    final count = PermutasUnificadasUtils.countImediatosMatches(
      original,
      piResults,
      piIds,
    );

    if (count == 0) {
      if (piStillLoading || (dash.isLoadingMatches && original == null)) {
        return Text(
          'Buscando combinações...',
          style: PermutaUnificadaTheme.monoStyle(11, PermutaUnificadaTheme.textMuted),
        );
      }
      if (original == null && piResults == null) {
        return _errorBox('Não foi possível carregar matches imediatos.',
            onRetry: () {
          dash.fetchMatches();
          pi.fetchMatches();
        });
      }
      return const SizedBox.shrink();
    }

    return _buildMatchHierarchy(
      diretas: original != null
          ? PermutasUnificadasUtils.filterOriginalMatches(original.diretas, piIds)
          : const [],
      ciclos: const [],
      triangulares: original != null
          ? PermutasUnificadasUtils.filterDuplicateTriangulares(
              original.triangulares,
              piExactTri,
            )
          : const [],
      triangularesProximas: const [],
      proximas: const [],
      interessados: const [],
      smartDiretas: piResults?.diretas ?? const [],
      smartProximas: const [],
      smartInteressados: const [],
      smartTriangulares: piExactTri,
      showDiretas: true,
      showCiclos: false,
      showTriangulares: true,
      showTriangularesProximas: false,
      showProximas: false,
      showInteressados: false,
      piFirst: true,
    );
  }

  Widget _buildMotorInteligenteSection(DashboardProvider dash, PermutasInteligentesProvider pi) {
    final ciclosCount = pi.results?.ciclosN.length ?? 0;

    return _sectionCard(
      icon: Icons.psychology,
      iconColor: PermutaUnificadaTheme.heroBlue,
      title: 'Motor Inteligente',
      subtitle: pi.isLoading && pi.results == null
          ? 'Analisando grafo de permutas...'
          : 'Ciclos em cadeia e mapa de conexões',
      badge: ciclosCount > 0 ? '$ciclosCount' : null,
      initiallyExpanded: _motorInteligenteExpanded,
      onExpansionChanged: (v) => setState(() => _motorInteligenteExpanded = v),
      child: _buildMotorInteligenteContent(dash, pi),
    );
  }

  Widget _buildMotorInteligenteContent(DashboardProvider dash, PermutasInteligentesProvider pi) {
    if (pi.isLoading && pi.results == null) {
      return Column(
        children: [
          _shimmerList(4),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text('Mapeando ciclos N-way...',
                  style: PermutaUnificadaTheme.monoStyle(10)),
            ],
          ),
        ],
      );
    }

    if (pi.error != null) {
      return _errorBox(pi.error!, onRetry: () => pi.fetchMatches(refresh: true));
    }

    final results = pi.results;
    if (results == null) {
      return FilledButton(
        onPressed: () => pi.fetchMatches(),
        style: FilledButton.styleFrom(
          backgroundColor: PermutaUnificadaTheme.heroBlue,
        ),
        child: const Text('Ativar motor inteligente'),
      );
    }

    final original = dash.matches;
    final piIds = _piIds(pi);
    final ciclosCount = results.ciclosN.length;
    final imediatosCount = PermutasUnificadasUtils.countImediatosMatches(
      original,
      results,
      piIds,
    );

    if (ciclosCount == 0 && imediatosCount == 0 && !_hasAnyResults(dash, pi)) {
      return _buildEmptyState(dash, results);
    }

    final user = dash.userData;
    final location = [
      user?.municipioAtualNome,
      user?.estadoAtualSigla,
    ].whereType<String>().where((s) => s.isNotEmpty).join('-');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (results.configuracao.regraPermuta.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: PermutaUnificadaTheme.glassCard(),
            child: Text(
              results.configuracao.regraPermuta,
              style: PermutaUnificadaTheme.monoStyle(10, PermutaUnificadaTheme.textPrimary),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (ciclosCount > 0)
          _buildMatchHierarchy(
            diretas: const [],
            ciclos: results.ciclosN,
            triangulares: const [],
            triangularesProximas: const [],
            proximas: const [],
            interessados: const [],
            smartDiretas: const [],
            smartProximas: const [],
            smartInteressados: const [],
            smartTriangulares: const [],
            showDiretas: false,
            showCiclos: true,
            showTriangulares: false,
            showTriangularesProximas: false,
            showProximas: false,
            showInteressados: false,
          )
        else
          Text(
            'Nenhum ciclo em cadeia no momento.',
            style: PermutaUnificadaTheme.monoStyle(11, PermutaUnificadaTheme.textMuted),
          ),
        const SizedBox(height: 12),
        _buildMapaColapsavel(results, location),
      ],
    );
  }

  Widget _buildProximidadeSection(DashboardProvider dash, PermutasInteligentesProvider pi) {
    final piIds = _piIds(pi);
    final original = dash.matches;
    final piResults = pi.results;
    final count = PermutasUnificadasUtils.countProximidadeMatches(
      original,
      piResults,
      piIds,
    );

    return _sectionCard(
      icon: Icons.radar,
      iconColor: PermutaUnificadaTheme.accentChain,
      title: 'Match por Proximidade',
      subtitle: 'Combinações via raio de proximidade configurado',
      badge: count > 0 ? '$count' : null,
      initiallyExpanded: _proximidadeExpanded,
      onExpansionChanged: (v) => setState(() => _proximidadeExpanded = v),
      child: _buildProximidadeContent(dash, pi, piIds),
    );
  }

  Widget _buildProximidadeContent(
    DashboardProvider dash,
    PermutasInteligentesProvider pi,
    Set<int> piIds,
  ) {
    if ((dash.isLoadingMatches && dash.matches == null) ||
        (pi.isLoading && pi.results == null)) {
      return _shimmerList(2);
    }

    final original = dash.matches;
    final piResults = pi.results;
    final count = PermutasUnificadasUtils.countProximidadeMatches(
      original,
      piResults,
      piIds,
    );

    if (count == 0) {
      return Text(
        'Nenhum match por proximidade no momento.',
        style: PermutaUnificadaTheme.monoStyle(11, PermutaUnificadaTheme.textMuted),
      );
    }

    return _buildMatchHierarchy(
      diretas: const [],
      ciclos: const [],
      triangulares: const [],
      triangularesProximas: original?.triangularesProximas ?? const [],
      proximas: original != null
          ? PermutasUnificadasUtils.filterOriginalMatches(original.proximas, piIds)
          : const [],
      interessados: const [],
      smartDiretas: const [],
      smartProximas: piResults?.proximas ?? const [],
      smartInteressados: const [],
      smartTriangulares:
          piResults?.triangulares.where((t) => t.porAproximacao).toList() ?? const [],
      showDiretas: false,
      showCiclos: false,
      showTriangulares: false,
      showTriangularesProximas: true,
      showProximas: true,
      showInteressados: false,
    );
  }

  Widget _buildInteressadosSection(DashboardProvider dash, PermutasInteligentesProvider pi) {
    final piIds = _piIds(pi);
    final count = PermutasUnificadasUtils.countInteressadosMatches(
      dash.matches,
      pi.results,
      piIds,
    );

    return _sectionCard(
      icon: Icons.favorite_border,
      iconColor: PermutaUnificadaTheme.accentMutedGreen,
      title: 'Interessados na sua vaga',
      subtitle: 'Policiais que querem a sua região atual',
      badge: count > 0 ? '$count' : null,
      initiallyExpanded: _interessadosExpanded,
      onExpansionChanged: (v) => setState(() => _interessadosExpanded = v),
      child: KeyedSubtree(
        key: _interessadosKey,
        child: _buildInteressadosContent(dash, pi, piIds),
      ),
    );
  }

  Widget _buildInteressadosContent(
    DashboardProvider dash,
    PermutasInteligentesProvider pi,
    Set<int> piIds,
  ) {
    if ((dash.isLoadingMatches && dash.matches == null) ||
        (pi.isLoading && pi.results == null)) {
      return _shimmerList(2);
    }

    final original = dash.matches;
    final piResults = pi.results;
    final count = PermutasUnificadasUtils.countInteressadosMatches(
      original,
      piResults,
      piIds,
    );

    if (count == 0) {
      return Text(
        'Ninguém interessado na sua vaga por enquanto.',
        style: PermutaUnificadaTheme.monoStyle(11, PermutaUnificadaTheme.textMuted),
      );
    }

    return _buildMatchHierarchy(
      diretas: const [],
      ciclos: const [],
      triangulares: const [],
      triangularesProximas: const [],
      proximas: const [],
      interessados: original != null
          ? PermutasUnificadasUtils.filterOriginalMatches(original.interessados, piIds)
          : const [],
      smartDiretas: const [],
      smartProximas: const [],
      smartInteressados: piResults?.interessados ?? const [],
      smartTriangulares: const [],
      showDiretas: false,
      showCiclos: false,
      showTriangulares: false,
      showTriangularesProximas: false,
      showProximas: false,
      showInteressados: true,
    );
  }

  Widget _buildMatchHierarchy({
    required List<Match> diretas,
    required List<CicloNWay> ciclos,
    required List<MatchTriangular> triangulares,
    required List<MatchTriangular> triangularesProximas,
    required List<Match> proximas,
    required List<Match> interessados,
    required List<SmartMatch> smartDiretas,
    required List<SmartMatch> smartProximas,
    required List<SmartMatch> smartInteressados,
    required List<MatchTriangular> smartTriangulares,
    GlobalKey? interessadosKey,
    int initialCount = 5,
    bool showDiretas = true,
    bool showCiclos = true,
    bool showTriangulares = true,
    bool showTriangularesProximas = true,
    bool showProximas = true,
    bool showInteressados = true,
    bool piFirst = false,
  }) {
    List<PermutasItemBuilder> matchBuilders(List<Match> list, MatchTipo tipo) => list
        .map(
          (m) => () => RepaintBoundary(
            child: MatchCard(
              match: m,
              tipo: tipo,
              jaSolicitado: _jaSolicitado(m),
              onContatoSolicitado: () => _marcarSolicitado(m.id),
            ),
          ),
        )
        .toList();

    List<PermutasItemBuilder> smartBuilders(List<SmartMatch> list, MatchTipo tipo) => list
        .map(
          (m) => () => RepaintBoundary(
            child: MatchCard.fromSmart(
              m,
              tipo: tipo,
              jaSolicitado: _jaSolicitado(m),
              onContatoSolicitado: () => _marcarSolicitado(m.id),
            ),
          ),
        )
        .toList();

    List<PermutasItemBuilder> triBuilders(
      List<MatchTriangular> list, {
      bool porProximidade = false,
    }) =>
        list
            .map(
              (t) => () => RepaintBoundary(
                child: TriangularMatchCard(
                  match: t,
                  porProximidade: porProximidade,
                  jaSolicitado: _jaSolicitado,
                  onContatoSolicitado: _marcarSolicitado,
                  displayName: _displayName,
                  isAnonimo: _isAnonimo,
                ),
              ),
            )
            .toList();

    final diretasAll = piFirst
        ? [
            ...smartBuilders(smartDiretas, MatchTipo.direta),
            ...matchBuilders(diretas, MatchTipo.direta),
          ]
        : [
            ...matchBuilders(diretas, MatchTipo.direta),
            ...smartBuilders(smartDiretas, MatchTipo.direta),
          ];
    final ciclosAll = ciclos
        .map(
          (c) => () => RepaintBoundary(
            child: CicloNWayCard(
              ciclo: c,
              displayName: _displayName,
              isAnonimo: _isAnonimo,
            ),
          ),
        )
        .toList();
    final triAll = piFirst
        ? [
            ...smartTriangulares.map(
              (t) => () => RepaintBoundary(
                child: TriangularMatchCard(
                  match: t,
                  porProximidade: t.porAproximacao,
                  jaSolicitado: _jaSolicitado,
                  onContatoSolicitado: _marcarSolicitado,
                  displayName: _displayName,
                  isAnonimo: _isAnonimo,
                ),
              ),
            ),
            ...triBuilders(triangulares),
          ]
        : [
            ...triBuilders(triangulares),
            ...smartTriangulares.map(
              (t) => () => RepaintBoundary(
                child: TriangularMatchCard(
                  match: t,
                  porProximidade: t.porAproximacao,
                  jaSolicitado: _jaSolicitado,
                  onContatoSolicitado: _marcarSolicitado,
                  displayName: _displayName,
                  isAnonimo: _isAnonimo,
                ),
              ),
            ),
          ];
    final triProxAll = triBuilders(triangularesProximas, porProximidade: true);
    final proxAll = [...matchBuilders(proximas, MatchTipo.proxima), ...smartBuilders(smartProximas, MatchTipo.proxima)];
    final intAll = [
      ...matchBuilders(interessados, MatchTipo.interessado),
      ...smartBuilders(smartInteressados, MatchTipo.interessado),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDiretas && diretasAll.isNotEmpty)
          PermutasLazySubsection(
            title: 'Permutas diretas exatas',
            itemBuilders: diretasAll,
            initialCount: initialCount,
          ),
        if (showCiclos && ciclosAll.isNotEmpty)
          PermutasLazySubsection(
            title: 'Ciclos em cadeia (4+ participantes)',
            itemBuilders: ciclosAll,
            highlight: true,
            initialCount: 3,
          ),
        if (showTriangulares && triAll.isNotEmpty)
          PermutasLazySubsection(
            title: 'Permutas triangulares',
            itemBuilders: triAll,
            initialCount: initialCount,
          ),
        if (showTriangularesProximas && triProxAll.isNotEmpty)
          PermutasLazySubsection(
            title: 'Triangulares por proximidade',
            itemBuilders: triProxAll,
            initialCount: initialCount,
          ),
        if (showProximas && proxAll.isNotEmpty)
          PermutasLazySubsection(
            title: 'Por proximidade / raio configurado',
            itemBuilders: proxAll,
            initialCount: initialCount,
          ),
        if (showInteressados && intAll.isNotEmpty)
          KeyedSubtree(
            key: interessadosKey,
            child: PermutasLazySubsection(
              title: 'Interessados compatíveis',
              itemBuilders: intAll,
              initialCount: initialCount,
            ),
          ),
      ],
    );
  }

  Widget _buildMapaColapsavel(SmartMatchResults results, String location) {
    return Container(
      decoration: PermutaUnificadaTheme.panelDecoration(
        borderColor: PermutaUnificadaTheme.accentBlue,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _mapaExpanded,
          onExpansionChanged: (v) {
            setState(() {
              _mapaExpanded = v;
              if (v && !identical(_cachedGraphSource, results)) {
                _cachedGraphSource = results;
                _cachedGraph = PermutaGraphData.fromResults(
                  results,
                  selfLabel: 'Você',
                  selfSubtitle: location.isEmpty ? null : location,
                );
              }
            });
          },
          leading: const Icon(Icons.hub, color: PermutaUnificadaTheme.accentBlue, size: 20),
          title: Text('Ver mapa de conexões', style: PermutaUnificadaTheme.titleStyle(12)),
          subtitle: Text(
            _mapaExpanded && _cachedGraph != null
                ? '${_cachedGraph!.nodes.length} nós · toque para explorar'
                : 'Expandir para visualizar',
            style: PermutaUnificadaTheme.monoStyle(9),
          ),
          children: [
            if (_mapaExpanded && _cachedGraph != null)
              SizedBox(
                height: 260,
                child: PermutaGraphCanvas(
                  graph: _cachedGraph!,
                  onNodeTap: (node) {
                    if (node.policialId == null) return;
                    final match = _findMatchInResults(results, node.policialId!);
                    if (match != null) {
                      PermutaContactActions.enviarMensagemParaMatch(context, match);
                    }
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Match? _findMatchInResults(SmartMatchResults results, int id) {
    for (final m in results.diretas) {
      if (m.id == id) return m;
    }
    for (final m in results.proximas) {
      if (m.id == id) return m;
    }
    for (final m in results.interessados) {
      if (m.id == id) return m;
    }
    for (final c in results.ciclosN) {
      for (final p in c.participantes) {
        if (p.id == id) return p;
      }
    }
    for (final t in results.triangulares) {
      if (t.policialB.id == id) return t.policialB;
      if (t.policialC.id == id) return t.policialC;
    }
    return null;
  }

  Widget _buildEmptyState(DashboardProvider dash, SmartMatchResults? piResults) {
    final message = PermutasUnificadasUtils.emptyStateMessage(
      intencoes: dash.intencoes,
      graphNodes: piResults?.graphStats.nodes,
    );

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: PermutaUnificadaTheme.panelDecoration(),
      child: Column(
        children: [
          Icon(Icons.search_off,
              size: 56,
              color: PermutaUnificadaTheme.accentBlue.withValues(alpha: 0.5)),
          const SizedBox(height: 14),
          Text('Sem combinações agora', style: PermutaUnificadaTheme.titleStyle(16)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: PermutaUnificadaTheme.monoStyle(11),
          ),
          if (dash.intencoes.isEmpty) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => ChangeNotifierProvider.value(
                    value: dash,
                    child: const GerirIntencoesModal(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Adicionar intenção'),
              style: FilledButton.styleFrom(
                backgroundColor: PermutaUnificadaTheme.accentBlueDeep,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
    String? badge,
    bool initiallyExpanded = true,
    ValueChanged<bool>? onExpansionChanged,
  }) {
    return Container(
      decoration: PermutaUnificadaTheme.panelDecoration(),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: onExpansionChanged,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Row(
            children: [
              Expanded(child: Text(title, style: PermutaUnificadaTheme.titleStyle(13))),
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: PermutaUnificadaTheme.bgGlass,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PermutaUnificadaTheme.border),
                  ),
                  child: Text(
                    badge,
                    style: PermutaUnificadaTheme.monoStyle(
                      9,
                      PermutaUnificadaTheme.accent,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(subtitle, style: PermutaUnificadaTheme.monoStyle(10)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerList(int count) {
    return Column(
      children: List.generate(count, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Shimmer.fromColors(
            baseColor: PermutaUnificadaTheme.bgGlass,
            highlightColor: PermutaUnificadaTheme.bgPanel,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: PermutaUnificadaTheme.bgGlass,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _errorBox(String message, {required VoidCallback onRetry}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: PermutaUnificadaTheme.glassCard(
        accent: Colors.red.shade300,
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: PermutaUnificadaTheme.monoStyle(11)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}