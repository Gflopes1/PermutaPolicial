// /lib/features/dashboard/widgets/resultados_permuta_widget.dart

import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';

import '../../../core/models/match_results.dart';
import 'match_triangular_card.dart';
import '../../permutas/utils/permuta_contact_actions.dart';
import '../../notificacoes/providers/notificacoes_provider.dart';

class ResultadosPermutaWidget extends StatefulWidget {
  final FullMatchResults results;
  const ResultadosPermutaWidget({super.key, required this.results});

  @override
  State<ResultadosPermutaWidget> createState() => _ResultadosPermutaWidgetState();
}

class _ResultadosPermutaWidgetState extends State<ResultadosPermutaWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Estado para gerenciar os filtros de múltipla escolha
  List<String> _filtrosPostoSelecionados = [];
  List<String> _opcoesDeFiltro = [];
  final Set<int> _contatosSolicitados = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _popularOpcoesDeFiltro();
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

  @override
  void didUpdateWidget(covariant ResultadosPermutaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se os resultados mudarem (ex: refresh na dashboard), atualiza as opções de filtro
    if (widget.results != oldWidget.results) {
      _popularOpcoesDeFiltro();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Coleta os postos/graduações dos resultados para criar as opções de filtro
  void _popularOpcoesDeFiltro() {
    final allMatches = [
      ...widget.results.diretas,
      ...widget.results.interessados,
      ...widget.results.proximas,
      ...widget.results.triangulares.map((t) => t.policialB),
      ...widget.results.triangulares.map((t) => t.policialC),
    ];

    final allPostos = allMatches
        .map((m) => m.postoGraduacaoNome)
        .whereType<String>()
        .where((p) => p.isNotEmpty)
        .toSet();

    setState(() {
      _opcoesDeFiltro = allPostos.toList()..sort();
      // Limpa os filtros selecionados se eles não existirem mais nos novos resultados
      _filtrosPostoSelecionados.removeWhere((filtro) => !allPostos.contains(filtro));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- LÓGICA DO FILTRO ---
    // As listas são filtradas aqui antes de serem passadas para a UI
    final diretasFiltradas = widget.results.diretas.where((match) {
        if (_filtrosPostoSelecionados.isEmpty) return true;
        return _filtrosPostoSelecionados.contains(match.postoGraduacaoNome);
    }).toList();

    final interessadosFiltrados = widget.results.interessados.where((match) {
        if (_filtrosPostoSelecionados.isEmpty) return true;
        return _filtrosPostoSelecionados.contains(match.postoGraduacaoNome);
    }).toList();
    
    final triangularesFiltradas = widget.results.triangulares.where((match) {
        if (_filtrosPostoSelecionados.isEmpty) return true;
        return _filtrosPostoSelecionados.contains(match.policialB.postoGraduacaoNome) ||
               _filtrosPostoSelecionados.contains(match.policialC.postoGraduacaoNome);
    }).toList();

    final triangularesProxFiltradas = widget.results.triangularesProximas.where((match) {
        if (_filtrosPostoSelecionados.isEmpty) return true;
        return _filtrosPostoSelecionados.contains(match.policialB.postoGraduacaoNome) ||
               _filtrosPostoSelecionados.contains(match.policialC.postoGraduacaoNome);
    }).toList();

    final proximasFiltradas = widget.results.proximas.where((match) {
        if (_filtrosPostoSelecionados.isEmpty) return true;
        return _filtrosPostoSelecionados.contains(match.postoGraduacaoNome);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Resultados da Busca', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Card(
          color: theme.colorScheme.surface.withAlpha(128),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.results.configuracao.regraPermuta)),
              ],
            ),
          ),
        ),
        
        // ###############################################################
        // ###           WIDGET DO FILTRO POR POSTO/GRADUAÇÃO          ###
        // ###############################################################
        if (_opcoesDeFiltro.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: DropdownSearch<String>.multiSelection(
              items: _opcoesDeFiltro,
              selectedItems: _filtrosPostoSelecionados,
              onChanged: (List<String> novosFiltros) {
                setState(() {
                  _filtrosPostoSelecionados = novosFiltros;
                });
              },
              popupProps: PopupPropsMultiSelection.modalBottomSheet(
                showSearchBox: true,
                searchFieldProps: const TextFieldProps(decoration: InputDecoration(labelText: 'Pesquisar Posto/Graduação')),
                modalBottomSheetProps: ModalBottomSheetProps(backgroundColor: theme.scaffoldBackgroundColor),
                   itemBuilder: (context, item, isSelected) {
                    return ListTile(
                      title: Text(item),
                  );
                },
              ),
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: "Filtrar por Posto / Graduação",
                  hintText: "Selecione um ou mais...",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              clearButtonProps: const ClearButtonProps(isVisible: true),
            ),
          ),
        // ###############################################################
        // ###                       FIM DO FILTRO                     ###
        // ###############################################################

        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(child: Text('Diretas (${diretasFiltradas.length})')),
            Tab(child: Text('Próximas (${proximasFiltradas.length})')),
            Tab(child: Text('Triangulares (${triangularesFiltradas.length + triangularesProxFiltradas.length})')),
            Tab(child: Text('Interessados (${interessadosFiltrados.length})')),
          ],
        ),
        const SizedBox(height: 8),
        _buildActiveTabContent(
          diretasFiltradas: diretasFiltradas,
          proximasFiltradas: proximasFiltradas,
          triangularesFiltradas: triangularesFiltradas,
          triangularesProxFiltradas: triangularesProxFiltradas,
          interessadosFiltrados: interessadosFiltrados,
        ),
      ],
    );
  }

  Widget _buildActiveTabContent({
    required List<Match> diretasFiltradas,
    required List<Match> proximasFiltradas,
    required List<MatchTriangular> triangularesFiltradas,
    required List<MatchTriangular> triangularesProxFiltradas,
    required List<Match> interessadosFiltrados,
  }) {
    switch (_tabController.index) {
      case 0:
        return _buildMatchList(diretasFiltradas);
      case 1:
        return _buildProximasList(proximasFiltradas);
      case 2:
        return _buildTriangularList(triangularesFiltradas, triangularesProxFiltradas);
      case 3:
        return _buildInteressadosList(interessadosFiltrados);
      default:
        return const SizedBox.shrink();
    }
  }

  bool _jaSolicitado(Match match) =>
      match.jaSolicitado || _contatosSolicitados.contains(match.id);

  void _marcarSolicitado(int policialId) {
    setState(() => _contatosSolicitados.add(policialId));
  }

  Widget _buildMatchTitle(Match match, String nome) {
    return Row(
      children: [
        Expanded(child: Text(nome)),
        if (match.distanciaKm != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Chip(
              label: Text(
                '${match.distanciaKm!.toStringAsFixed(0)} km',
                style: const TextStyle(fontSize: 11),
              ),
              visualDensity: VisualDensity.compact,
              backgroundColor: Colors.blue.shade50,
              padding: EdgeInsets.zero,
            ),
          ),
        if (match.emDestaque)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Chip(
              label: const Text('Destaque', style: TextStyle(fontSize: 11)),
              visualDensity: VisualDensity.compact,
              backgroundColor: Colors.amber.shade100,
              padding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  Widget _buildProximasList(List<Match> matches) {
    if (!widget.results.configuracao.temRaioConfigurado && matches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Defina um raio (km) em suas intenções de município ou unidade para ver permutas próximas mútuas.',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (matches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Nenhuma permuta próxima mútua encontrada para o filtro selecionado.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return _buildMatchList(matches, tipoPermuta: 'proxima');
  }

  Widget _buildMatchList(
    List<Match> matches, {
    String tipoPermuta = 'direta',
    String emptyMessage = 'Nenhuma combinação direta encontrada para o filtro selecionado.',
  }) {
    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(emptyMessage, textAlign: TextAlign.center),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(matches.length, (index) {
        final match = matches[index];
        
        // Se o usuário estiver oculto no mapa, mostra informações genéricas e botões de ação
        if (match.ocultarNoMapa && !match.aceitouCompartilhar) {
          final cidade = match.municipioAtual ?? 'cidade não informada';
          final forca = match.forcaSigla;
          final unidade = match.unidadeAtual;
          
          String descricao = 'Usuário não identificado da cidade "$cidade", força "$forca"';
          if (unidade != null && unidade.isNotEmpty) {
            descricao += ', unidade "$unidade"';
          }
          descricao += tipoPermuta == 'proxima'
              ? ' está perto do seu destino desejado!'
              : ' tem uma permuta direta com você!';
          
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    descricao,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _jaSolicitado(match) ? null : () => PermutaContactActions.solicitarContato(
                            context,
                            destinatarioId: match.id,
                            tipoPermuta: tipoPermuta,
                            onSuccess: () => _marcarSolicitado(match.id),
                          ),
                          icon: Icon(_jaSolicitado(match) ? Icons.check_circle : Icons.person_add),
                          label: Text(_jaSolicitado(match) ? 'Contato Solicitado' : 'Solicitar Contato'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            disabledBackgroundColor: const Color.fromARGB(255, 190, 190, 190),
                            disabledForegroundColor: const Color.fromARGB(255, 35, 35, 35),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => PermutaContactActions.enviarMensagem(
                            context,
                            destinatarioId: match.id,
                            isAnonima: true,
                          ),
                          icon: const Icon(Icons.message),
                          label: const Text('Enviar Mensagem'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
        
        // ✅ Se aceitou compartilhar, mostra dados mesmo que esteja oculto (DIRETAS)
        if (match.ocultarNoMapa && match.aceitouCompartilhar && match.dadosAceitacao != null) {
          final dados = match.dadosAceitacao!;
          final nome = dados['nome'] ?? dados['aceitador_nome'] ?? 'Nome não informado';
          final contato = dados['contato'] ?? dados['aceitador_contato'];
          final forcaSigla = dados['forcaSigla'] ?? dados['aceitador_forca_sigla'] ?? match.forcaSigla;
          final cidadeNome = dados['cidadeNome'] ?? dados['aceitador_cidade_nome'] ?? match.municipioAtual ?? 'cidade não informada';
          final estadoSigla = dados['estadoSigla'] ?? dados['aceitador_estado_sigla'] ?? match.estadoAtual ?? '';
          final unidadeNome = dados['unidadeNome'] ?? dados['aceitador_unidade_nome'];
          final postoNome = dados['postoNome'] ?? dados['aceitador_posto_nome'];
          
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: ListTile(
              title: _buildMatchTitle(match, nome),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (postoNome != null && postoNome.isNotEmpty)
                    Text(postoNome, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                  Text('$forcaSigla | $cidadeNome - $estadoSigla'),
                  if (unidadeNome != null && unidadeNome.isNotEmpty)
                    Text(unidadeNome, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.message),
                    tooltip: 'Enviar Mensagem',
                    onPressed: () => PermutaContactActions.enviarMensagem(
                          context,
                          destinatarioId: match.id,
                        ),
                  ),
                  if (contato != null && contato.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone),
                      tooltip: 'Ver Contato',
                      onPressed: () => PermutaContactActions.showQsoDialog(
                        context,
                        match.copyWith(qso: contato),
                      ),
                    ),
                ],
              ),
            ),
          );
        }
        
        // Usuário não oculto: mostra informações completas
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: ListTile(
            title: _buildMatchTitle(match, match.nome),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (match.postoGraduacaoNome != null && match.postoGraduacaoNome!.isNotEmpty)
                  Text(match.postoGraduacaoNome!, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                if (tipoPermuta == 'proxima' && match.descricaoInteresse != null)
                  Text(match.descricaoInteresse!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                Text(
                  tipoPermuta == 'proxima'
                      ? 'Lotação atual: ${match.forcaSigla} | ${match.municipioAtual} - ${match.estadoAtual}'
                      : '${match.forcaSigla} | ${match.municipioAtual} - ${match.estadoAtual}',
                ),
                Text(
                  match.unidadeAtual ?? 'Unidade não informada',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.message),
                  tooltip: 'Enviar Mensagem',
                  onPressed: () => PermutaContactActions.enviarMensagem(
                          context,
                          destinatarioId: match.id,
                        ),
                ),
                if (match.qso != null && match.qso!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.phone),
                    tooltip: 'Ver Contato',
                    onPressed: () => PermutaContactActions.showQsoDialog(context, match),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
  
  Widget _buildInteressadosList(List<Match> matches) {
    if (matches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Nenhum interessado encontrado para o filtro selecionado.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(matches.length, (index) {
        final match = matches[index];
        
        // Se o usuário estiver oculto no mapa, mostra informações genéricas
        if (match.ocultarNoMapa && !match.aceitouCompartilhar) {
          final cidade = match.municipioAtual ?? 'cidade não informada';
          final forca = match.forcaSigla;
          final unidade = match.unidadeAtual;
          
          String descricao = 'Usuário não identificado da cidade "$cidade", força "$forca"';
          if (unidade != null && unidade.isNotEmpty) {
            descricao += ', unidade "$unidade"';
          }
          descricao += ' tem interesse em ${match.descricaoInteresse ?? "seu estado/cidade/unidade"}.';
          
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    descricao,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _jaSolicitado(match) ? null : () => PermutaContactActions.solicitarContato(
                            context,
                            destinatarioId: match.id,
                            tipoPermuta: 'interessado',
                            onSuccess: () => _marcarSolicitado(match.id),
                          ),
                      icon: Icon(_jaSolicitado(match) ? Icons.check_circle : Icons.person_add),
                      label: Text(_jaSolicitado(match) ? 'Contato Solicitado' : 'Solicitar Contato'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        disabledBackgroundColor: const Color.fromARGB(255, 190, 190, 190),
                        disabledForegroundColor: const Color.fromARGB(255, 35, 35, 35),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => PermutaContactActions.enviarMensagem(
                            context,
                            destinatarioId: match.id,
                            isAnonima: true,
                          ),
                      icon: const Icon(Icons.message),
                      label: const Text('Enviar Mensagem'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // ✅ Se aceitou compartilhar, mostra dados mesmo que esteja oculto (INTERESSADOS)
        if (match.ocultarNoMapa && match.aceitouCompartilhar && match.dadosAceitacao != null) {
          final dados = match.dadosAceitacao!;
          final nome = dados['nome'] ?? dados['aceitador_nome'] ?? 'Nome não informado';
          final contato = dados['contato'] ?? dados['aceitador_contato'];
          final forcaSigla = dados['forcaSigla'] ?? dados['aceitador_forca_sigla'] ?? match.forcaSigla;
          final cidadeNome = dados['cidadeNome'] ?? dados['aceitador_cidade_nome'] ?? match.municipioAtual ?? 'cidade não informada';
          final estadoSigla = dados['estadoSigla'] ?? dados['aceitador_estado_sigla'] ?? match.estadoAtual ?? '';
          final unidadeNome = dados['unidadeNome'] ?? dados['aceitador_unidade_nome'];
          final postoNome = dados['postoNome'] ?? dados['aceitador_posto_nome'];
          
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: ListTile(
              title: Text(nome),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (match.descricaoInteresse != null)
                    Text(match.descricaoInteresse!, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  if (postoNome != null && postoNome.isNotEmpty)
                    Text(postoNome, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                  Text('$forcaSigla | $cidadeNome - $estadoSigla'),
                  if (unidadeNome != null && unidadeNome.isNotEmpty)
                    Text(unidadeNome, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.message),
                    tooltip: 'Enviar Mensagem',
                    onPressed: () => PermutaContactActions.enviarMensagem(
                          context,
                          destinatarioId: match.id,
                        ),
                  ),
                  if (contato != null && contato.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone),
                      tooltip: 'Ver Contato',
                      onPressed: () => PermutaContactActions.showQsoDialog(
                        context,
                        match.copyWith(qso: contato),
                      ),
                    ),
                ],
              ),
            ),
          );
        }
        
        // Usuário não oculto - exibe normalmente
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: ListTile(
            title: _buildMatchTitle(match, match.nome),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (match.descricaoInteresse != null)
                  Text(match.descricaoInteresse!, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                if (match.postoGraduacaoNome != null && match.postoGraduacaoNome!.isNotEmpty)
                  Text(match.postoGraduacaoNome!, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                Text('${match.forcaSigla} | ${match.municipioAtual} - ${match.estadoAtual}'),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.message),
                  tooltip: 'Enviar Mensagem',
                  onPressed: () => PermutaContactActions.enviarMensagem(
                          context,
                          destinatarioId: match.id,
                        ),
                ),
                if (match.qso != null && match.qso!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.phone),
                    tooltip: 'Ver Contato',
                    onPressed: () =>
                        PermutaContactActions.showQsoDialog(context, match),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTriangularList(
    List<MatchTriangular> exatas,
    List<MatchTriangular> proximas,
  ) {
    if (exatas.isEmpty && proximas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Nenhuma combinação triangular encontrada para o filtro selecionado.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (exatas.isNotEmpty) ...[
          if (proximas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                'Combinações exatas (${exatas.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ...exatas.map(
            (match) => MatchTriangularCard(
              match: match,
              jaSolicitado: (m) => _jaSolicitado(m),
              onContatoSolicitado: _marcarSolicitado,
            ),
          ),
        ],
        if (proximas.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
            child: Text(
              'Por proximidade (${proximas.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (exatas.isEmpty && !widget.results.configuracao.temRaioConfigurado)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'Triangulares por aproximação aparecem quando você ou os participantes definem raio (km) nas intenções.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ...proximas.map(
            (match) => MatchTriangularCard(
              match: match,
              jaSolicitado: (m) => _jaSolicitado(m),
              onContatoSolicitado: _marcarSolicitado,
            ),
          ),
        ],
      ],
    );
  }
}