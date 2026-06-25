import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/match_results.dart';
import '../../../core/models/smart_match_results.dart';
import '../../permutas/utils/permuta_contact_actions.dart';
import '../../notificacoes/providers/notificacoes_provider.dart';
import 'permuta_graph_canvas.dart';
import 'permuta_graph_model.dart';
import 'permuta_inteligente_theme.dart';

class ResultadosPermutaInteligenteWidget extends StatefulWidget {
  final SmartMatchResults results;
  final String? userName;
  final String? userLocation;

  const ResultadosPermutaInteligenteWidget({
    super.key,
    required this.results,
    this.userName,
    this.userLocation,
  });

  @override
  State<ResultadosPermutaInteligenteWidget> createState() =>
      _ResultadosPermutaInteligenteWidgetState();
}

class _ResultadosPermutaInteligenteWidgetState
    extends State<ResultadosPermutaInteligenteWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PermutaGraphData _graph;
  final Set<int> _contatosSolicitados = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _rebuildGraph();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarContatosSolicitados());
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

  bool _jaSolicitado(Match match) =>
      match.jaSolicitado || _contatosSolicitados.contains(match.id);

  void _marcarSolicitado(int id) => setState(() => _contatosSolicitados.add(id));

  bool _isAnonimo(Match match) => match.ocultarNoMapa && !match.aceitouCompartilhar;

  String _displayName(Match match) {
    if (_isAnonimo(match)) return 'Usuário não identificado';
    if (match.ocultarNoMapa && match.aceitouCompartilhar && match.dadosAceitacao != null) {
      return match.dadosAceitacao!['nome']?.toString() ??
          match.dadosAceitacao!['aceitador_nome']?.toString() ??
          match.nome;
    }
    return match.nome;
  }

  Match? _findMatchById(int id) {
    for (final m in widget.results.diretas) {
      if (m.id == id) return m;
    }
    for (final m in widget.results.proximas) {
      if (m.id == id) return m;
    }
    for (final m in widget.results.interessados) {
      if (m.id == id) return m;
    }
    for (final c in widget.results.ciclosN) {
      for (final p in c.participantes) {
        if (p.id == id) return p;
      }
    }
    for (final t in widget.results.triangulares) {
      if (t.policialB.id == id) return t.policialB;
      if (t.policialC.id == id) return t.policialC;
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant ResultadosPermutaInteligenteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.results != widget.results) _rebuildGraph();
  }

  void _rebuildGraph() {
    _graph = PermutaGraphData.fromResults(
      widget.results,
      selfLabel: 'Você',
      selfSubtitle: widget.userLocation,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.results;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGraphHero(),
        const SizedBox(height: 14),
        _buildMetricsRow(r),
        const SizedBox(height: 12),
        _buildLegend(),
        const SizedBox(height: 14),
        _buildInteligencePanel(r),
        const SizedBox(height: 16),
        _buildTabBar(r),
        const SizedBox(height: 10),
        _buildActiveTab(r),
      ],
    );
  }

  Widget _buildGraphHero() {
    return Container(
      height: 300,
      decoration: PermutaInteligenteTheme.panelDecoration(
        borderColor: PermutaInteligenteTheme.accentCyan,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    PermutaInteligenteTheme.accentPurple.withValues(alpha: 0.12),
                    PermutaInteligenteTheme.bgDeep,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 14,
            right: 14,
            child: Row(
              children: [
                Icon(Icons.hub, color: PermutaInteligenteTheme.accentCyan, size: 18),
                const SizedBox(width: 8),
                Text('Mapa de Conexões', style: PermutaInteligenteTheme.titleStyle(14)),
                const Spacer(),
                if (_graph.hiddenCount > 0)
                  Text(
                    '+${_graph.hiddenCount} ocultos',
                    style: PermutaInteligenteTheme.monoStyle(9),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 44,
            left: 0,
            right: 0,
            bottom: 36,
            child: PermutaGraphCanvas(
              graph: _graph,
              onNodeTap: _onGraphNodeTap,
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Text(
              'Você no centro • até 8 melhores conexões • toque para detalhes',
              style: PermutaInteligenteTheme.monoStyle(10),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(SmartMatchResults r) {
    return Row(
      children: [
        Expanded(child: _metricTile('Matches', '${r.totalMatches}', PermutaInteligenteTheme.accentCyan)),
        const SizedBox(width: 8),
        Expanded(
          child: _metricTile(
            'Top Score',
            _graph.topScore?.toStringAsFixed(0) ?? '—',
            PermutaInteligenteTheme.accentGreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metricTile(
            'Ciclos N',
            '${r.ciclosN.length}',
            PermutaInteligenteTheme.accentAmber,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metricTile(
            'Nós',
            '${_graph.nodes.length}',
            PermutaInteligenteTheme.accentPurple,
          ),
        ),
      ],
    );
  }

  Widget _metricTile(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: PermutaInteligenteTheme.glassCard(accent: accent),
      child: Column(
        children: [
          Text(value, style: PermutaInteligenteTheme.titleStyle(20).copyWith(color: accent)),
          const SizedBox(height: 2),
          Text(label, style: PermutaInteligenteTheme.monoStyle(10)),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: [
        _legendDot('Você', PermutaInteligenteTheme.accentCyan),
        _legendDot('Direta', PermutaInteligenteTheme.accentGreen),
        _legendDot('Ciclo', PermutaInteligenteTheme.accentPurple),
        _legendDot('N-way', PermutaInteligenteTheme.accentAmber),
        _legendDot('Interessado', const Color(0xFFFF6090)),
      ],
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: PermutaInteligenteTheme.monoStyle(10)),
      ],
    );
  }

  Widget _buildInteligencePanel(SmartMatchResults r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: PermutaInteligenteTheme.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: PermutaInteligenteTheme.accentPurple, size: 20),
              const SizedBox(width: 8),
              Text('Análise do Motor', style: PermutaInteligenteTheme.titleStyle(13)),
              const Spacer(),
              if (r.cache.hit)
                Text('cache', style: PermutaInteligenteTheme.monoStyle(9, PermutaInteligenteTheme.accentGreen)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            r.configuracao.regraPermuta,
            style: PermutaInteligenteTheme.monoStyle(11, PermutaInteligenteTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(SmartMatchResults r) {
    return Container(
      decoration: BoxDecoration(
        color: PermutaInteligenteTheme.bgPanel.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [
              PermutaInteligenteTheme.accentPurple.withValues(alpha: 0.5),
              PermutaInteligenteTheme.accentCyan.withValues(alpha: 0.35),
            ],
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: PermutaInteligenteTheme.textPrimary,
        unselectedLabelColor: PermutaInteligenteTheme.textMuted,
        labelStyle: PermutaInteligenteTheme.monoStyle(11, PermutaInteligenteTheme.textPrimary),
        unselectedLabelStyle: PermutaInteligenteTheme.monoStyle(11),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: 'Grafo'),
          Tab(text: 'Permuta 4+ (${r.ciclosN.length})'),
          Tab(text: 'Diretas (${r.diretas.length})'),
          Tab(text: 'Próximas (${r.proximas.length})'),
          Tab(text: '△ ${r.triangulares.length}'),
          Tab(text: 'Int. ${r.interessados.length}'),
        ],
      ),
    );
  }

  Widget _buildActiveTab(SmartMatchResults r) {
    switch (_tabController.index) {
      case 0:
        return _buildGraphDetailTab();
      case 1:
        return _buildCiclosList(r.ciclosN);
      case 2:
        return _buildSmartMatchList(r.diretas, tipoPermuta: 'direta');
      case 3:
        return _buildSmartMatchList(r.proximas, tipoPermuta: 'proxima');
      case 4:
        return _buildTriangularList(r.triangulares);
      case 5:
        return _buildSmartMatchList(r.interessados, tipoPermuta: 'interessado');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGraphDetailTab() {
    final edges = _graph.edges.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: PermutaInteligenteTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Topologia detectada', style: PermutaInteligenteTheme.titleStyle(14)),
          const SizedBox(height: 10),
          _graphStatRow('Nós no grafo', '${_graph.nodes.length}'),
          _graphStatRow('Arestas (intenções)', '$edges'),
          _graphStatRow('Matches ranqueados', '${_graph.totalMatches}'),
          const SizedBox(height: 12),
          Text(
            'Apenas a mesma corporação (${widget.results.configuracao.forcaSigla}). '
            'Intenção ESTADO só na permuta interestadual; intraestadual usa unidade e município. '
            'Detecta ciclos de até 6 participantes e ranqueia por score heurístico.',
            style: PermutaInteligenteTheme.monoStyle(11, PermutaInteligenteTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _graphStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: PermutaInteligenteTheme.monoStyle(11))),
          Text(value, style: PermutaInteligenteTheme.monoStyle(11, PermutaInteligenteTheme.accentCyan)),
        ],
      ),
    );
  }

  void _onGraphNodeTap(PermutaGraphNode node) {
    if (node.policialId == null) return;
    final match = _findMatchById(node.policialId!);
    final anonimo = match != null && _isAnonimo(match);
    showModalBottomSheet(
      context: context,
      backgroundColor: PermutaInteligenteTheme.bgPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              match != null ? _displayName(match) : node.label,
              style: PermutaInteligenteTheme.titleStyle(16),
            ),
            if (node.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(node.subtitle!, style: PermutaInteligenteTheme.monoStyle(12)),
            ],
            if (node.score != null) ...[
              const SizedBox(height: 8),
              Text('Score ${node.score!.toStringAsFixed(0)}',
                  style: PermutaInteligenteTheme.monoStyle(12, PermutaInteligenteTheme.accentGreen)),
            ],
            if (anonimo) ...[
              const SizedBox(height: 12),
              Text(
                'Este usuário está com privacidade ativa. A identidade dele permanece oculta; '
                'a sua será visível na conversa.',
                style: PermutaInteligenteTheme.monoStyle(11, PermutaInteligenteTheme.textMuted),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                if (match != null) {
                  PermutaContactActions.enviarMensagemParaMatch(context, match);
                } else {
                  PermutaContactActions.enviarMensagem(
                    context,
                    destinatarioId: node.policialId!,
                    isAnonima: anonimo,
                  );
                }
              },
              icon: const Icon(Icons.message),
              label: const Text('Enviar Mensagem'),
              style: FilledButton.styleFrom(
                backgroundColor: PermutaInteligenteTheme.accentPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip(double? score) {
    if (score == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: PermutaInteligenteTheme.accentGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PermutaInteligenteTheme.accentGreen.withValues(alpha: 0.35)),
      ),
      child: Text(
        '${score.toStringAsFixed(0)} pts',
        style: PermutaInteligenteTheme.monoStyle(10, PermutaInteligenteTheme.accentGreen),
      ),
    );
  }

  Widget _buildSmartMatchList(List<SmartMatch> matches, {String tipoPermuta = 'direta'}) {
    if (matches.isEmpty) {
      return _emptyState('Nenhum resultado nesta categoria.');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: matches.map((match) => _buildSmartMatchCard(match, tipoPermuta: tipoPermuta)).toList(),
    );
  }

  Widget _buildSmartMatchCard(SmartMatch match, {String tipoPermuta = 'direta'}) {
    if (_isAnonimo(match)) {
      final cidade = match.municipioAtual ?? 'cidade não informada';
      final forca = match.forcaSigla;
      final unidade = match.unidadeAtual;
      var descricao = 'Usuário não identificado da cidade "$cidade", força "$forca"';
      if (unidade != null && unidade.isNotEmpty) {
        descricao += ', unidade "$unidade"';
      }
      descricao += tipoPermuta == 'proxima'
          ? ' está perto do seu destino desejado!'
          : ' tem interesse compatível com você!';

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: PermutaInteligenteTheme.glassCard(accent: PermutaInteligenteTheme.accentCyan),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.visibility_off, size: 16, color: PermutaInteligenteTheme.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(descricao, style: PermutaInteligenteTheme.monoStyle(11)),
                ),
                _buildScoreChip(match.score),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _jaSolicitado(match)
                        ? null
                        : () => PermutaContactActions.solicitarContato(
                              context,
                              destinatarioId: match.id,
                              tipoPermuta: tipoPermuta,
                              onSuccess: () => _marcarSolicitado(match.id),
                            ),
                    icon: Icon(_jaSolicitado(match) ? Icons.check_circle : Icons.person_add, size: 18),
                    label: Text(_jaSolicitado(match) ? 'Contato Solicitado' : 'Solicitar Contato'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PermutaInteligenteTheme.accentCyan,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        PermutaContactActions.enviarMensagemParaMatch(context, match),
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('Enviar Mensagem'),
                    style: FilledButton.styleFrom(
                      backgroundColor: PermutaInteligenteTheme.accentPurple,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final nome = _displayName(match);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: PermutaInteligenteTheme.glassCard(
        accent: PermutaInteligenteTheme.accentCyan,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: PermutaInteligenteTheme.accentCyan.withValues(alpha: 0.5),
              ),
            ),
            child: const Icon(Icons.person, color: PermutaInteligenteTheme.accentCyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(nome, style: PermutaInteligenteTheme.titleStyle(13)),
                    ),
                    _buildScoreChip(match.score),
                  ],
                ),
                if (match.descricaoInteresse != null) ...[
                  const SizedBox(height: 4),
                  Text(match.descricaoInteresse!,
                      style: PermutaInteligenteTheme.monoStyle(10, PermutaInteligenteTheme.textMuted)),
                ],
                const SizedBox(height: 4),
                Text(
                  '${match.forcaSigla} · ${match.municipioAtual ?? ''}-${match.estadoAtual ?? ''}',
                  style: PermutaInteligenteTheme.monoStyle(10),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _jaSolicitado(match)
                            ? null
                            : () => PermutaContactActions.solicitarContato(
                                  context,
                                  destinatarioId: match.id,
                                  tipoPermuta: tipoPermuta,
                                  onSuccess: () => _marcarSolicitado(match.id),
                                ),
                        icon: Icon(_jaSolicitado(match) ? Icons.check_circle : Icons.person_add, size: 16),
                        label: Text(_jaSolicitado(match) ? 'Solicitado' : 'Solicitar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PermutaInteligenteTheme.accentCyan,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.message_outlined, color: PermutaInteligenteTheme.accentPurple),
                      onPressed: () =>
                          PermutaContactActions.enviarMensagemParaMatch(context, match),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriangularList(List<MatchTriangular> matches) {
    if (matches.isEmpty) return _emptyState('Nenhuma permuta triangular.');

    return Column(
      children: matches.map((m) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: PermutaInteligenteTheme.glassCard(accent: PermutaInteligenteTheme.accentPurple),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.change_history, color: PermutaInteligenteTheme.accentPurple, size: 16),
                  const SizedBox(width: 6),
                  Text('Ciclo triangular', style: PermutaInteligenteTheme.titleStyle(12)),
                ],
              ),
              const SizedBox(height: 8),
              _flowLine(m.fluxo.aParaB),
              _flowLine(m.fluxo.bParaC),
              _flowLine(m.fluxo.cParaA),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  _nodeChip(m.policialB),
                  _nodeChip(m.policialC),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _flowLine(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('→ ', style: PermutaInteligenteTheme.monoStyle(10, PermutaInteligenteTheme.accentCyan)),
          Expanded(child: Text(text, style: PermutaInteligenteTheme.monoStyle(10))),
        ],
      ),
    );
  }

  Widget _nodeChip(Match p) {
    final nome = _displayName(p);
    final anonimo = _isAnonimo(p);
    return ActionChip(
      label: Text(nome, style: PermutaInteligenteTheme.monoStyle(10)),
      avatar: anonimo ? const Icon(Icons.visibility_off, size: 14) : null,
      backgroundColor: PermutaInteligenteTheme.bgGlass,
      side: BorderSide(color: PermutaInteligenteTheme.accentPurple.withValues(alpha: 0.4)),
      onPressed: () => PermutaContactActions.enviarMensagemParaMatch(context, p),
    );
  }

  String _localAtual(SmartMatch p) {
    final partes = <String>[];
    if (p.municipioAtual != null) {
      partes.add(p.estadoAtual != null ? '${p.municipioAtual}-${p.estadoAtual}' : p.municipioAtual!);
    }
    if (p.unidadeAtual != null) partes.add(p.unidadeAtual!);
    return partes.isEmpty ? 'local não informado' : partes.join(', ');
  }

  Widget _buildCiclosList(List<CicloNWay> ciclos) {
    if (ciclos.isEmpty) {
      return _emptyState('Nenhum ciclo com 4+ participantes.\nO motor busca cadeias de até 6 pessoas.');
    }

    return Column(
      children: ciclos.map((ciclo) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: PermutaInteligenteTheme.glassCard(accent: PermutaInteligenteTheme.accentAmber),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: PermutaInteligenteTheme.accentAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Permuta 4+',
                      style: PermutaInteligenteTheme.monoStyle(11, PermutaInteligenteTheme.accentAmber),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildScoreChip(ciclo.score),
                ],
              ),
              const SizedBox(height: 10),
              ...ciclo.participantes.where((p) => p.id > 0).map((p) {
                final texto = p.descricaoResumo ??
                    '${_displayName(p)}: está em ${_localAtual(p)} e vai para destino informado';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(texto, style: PermutaInteligenteTheme.monoStyle(10)),
                );
              }),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ciclo.participantes
                    .where((p) => p.id > 0)
                    .map((p) => _nodeChip(p))
                    .toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: PermutaInteligenteTheme.glassCard(),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: PermutaInteligenteTheme.monoStyle(12, PermutaInteligenteTheme.textMuted),
      ),
    );
  }
}
