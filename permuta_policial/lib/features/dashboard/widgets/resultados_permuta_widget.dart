// /lib/features/dashboard/widgets/resultados_permuta_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';

import '../../../core/models/match_results.dart';
import 'match_triangular_card.dart'; // Importa o card que separamos
import '../../notificacoes/providers/notificacoes_provider.dart';
import '../../chat/providers/chat_provider.dart';
import '../../chat/screens/chat_conversa_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _popularOpcoesDeFiltro();
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
    final allMatches = [...widget.results.diretas, ...widget.results.interessados];
    
    final allPostos = allMatches
        .map((m) => m.postoGraduacaoNome)
        .whereType<String>() // Garante que a lista não terá nulos
        .where((p) => p.isNotEmpty) // Garante que strings vazias não entrem
        .toSet(); // toSet() remove duplicatas

    setState(() {
      _opcoesDeFiltro = allPostos.toList()..sort();
      // Limpa os filtros selecionados se eles não existirem mais nos novos resultados
      _filtrosPostoSelecionados.removeWhere((filtro) => !allPostos.contains(filtro));
    });
  }

  void _showQsoDialog(BuildContext context, Match match) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final bool hasQso = match.qso != null && match.qso!.isNotEmpty;

        return AlertDialog(
          title: Text(match.nome),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasQso)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone),
                  title: const Text('QSO / Contato'),
                  subtitle: Text(
                    match.qso!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              else
                const Text('Este usuário não informou um número de contato.'),
            ],
          ),
          actions: <Widget>[
            if (hasQso)
              TextButton(
                child: const Text('Copiar Número'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: match.qso!));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Número copiado!'), backgroundColor: Colors.green),
                  );
                },
              ),
            TextButton(
              child: const Text('Fechar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          tabs: [
            Tab(child: Text('Diretas (${diretasFiltradas.length})')),
            Tab(child: Text('Triangulares (${triangularesFiltradas.length})')),
            Tab(child: Text('Interessados (${interessadosFiltrados.length})')),
          ],
        ),
        SizedBox(
          height: 400, 
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMatchList(diretasFiltradas),
              _buildTriangularList(triangularesFiltradas),
              _buildInteressadosList(interessadosFiltrados),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchList(List<Match> matches) {
    if (matches.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Nenhuma combinação direta encontrada para o filtro selecionado.')));
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        
        // Se o usuário estiver oculto no mapa, mostra informações genéricas e botões de ação
        if (match.ocultarNoMapa) {
          final cidade = match.municipioAtual ?? 'cidade não informada';
          final forca = match.forcaSigla;
          final unidade = match.unidadeAtual;
          
          String descricao = 'Usuário não identificado da cidade "$cidade", força "$forca"';
          if (unidade != null && unidade.isNotEmpty) {
            descricao += ', unidade "$unidade"';
          }
          descricao += ' tem uma permuta direta com você!';
          
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
                          onPressed: () => _solicitarContato(context, match.id),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Solicitar Contato'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _enviarMensagem(context, match.id, true),
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
        
        // Usuário não oculto: mostra informações completas
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: ListTile(
            title: Text(match.nome),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (match.postoGraduacaoNome != null && match.postoGraduacaoNome!.isNotEmpty)
                  Text(match.postoGraduacaoNome!, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                Text('${match.forcaSigla} | ${match.municipioAtual} - ${match.estadoAtual}'),
                Text(match.unidadeAtual ?? 'Unidade não informada', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.message),
                  tooltip: 'Enviar Mensagem',
                  onPressed: () => _enviarMensagem(context, match.id, false),
                ),
                if (match.qso != null && match.qso!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.phone),
                    tooltip: 'Ver Contato',
                    onPressed: () => _showQsoDialog(context, match),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildInteressadosList(List<Match> matches) {
     if (matches.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Nenhum interessado encontrado para o filtro selecionado.')));
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        
        // Se o usuário estiver oculto no mapa, mostra informações genéricas
        if (match.ocultarNoMapa) {
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
                      onPressed: () => _solicitarContato(context, match.id),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Solicitar Contato'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _enviarMensagem(context, match.id, true),
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
        
        // Usuário não oculto - exibe normalmente
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: ListTile(
            title: Text(match.nome),
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
                  onPressed: () => _enviarMensagem(context, match.id, false),
                ),
                IconButton(
                  icon: const Icon(Icons.phone),
                  tooltip: 'Ver Contato',
                  onPressed: () => _showQsoDialog(context, match),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _solicitarContato(BuildContext context, int destinatarioId) async {
    final notificacoesProvider = Provider.of<NotificacoesProvider>(context, listen: false);
    
    try {
      final success = await notificacoesProvider.criarSolicitacaoContato(destinatarioId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Solicitação de contato enviada com sucesso!' 
              : 'Erro ao enviar solicitação de contato.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar solicitação: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _enviarMensagem(BuildContext context, int destinatarioId, bool isAnonima) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    try {
      // Inicializa o socket se necessário
      await chatProvider.initializeSocket();
      
      // Inicia a conversa (anônima se especificado)
      final conversa = await chatProvider.iniciarConversa(destinatarioId, anonima: isAnonima);
      
      if (conversa != null && context.mounted) {
        // Navega para a tela de conversa
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => ChatConversaScreen(
              conversaId: conversa['id'],
              outroUsuarioNome: conversa['anonima'] && !conversa['remetente_revelado'] && conversa['iniciada_por'] == destinatarioId
                  ? 'Usuário não identificado'
                  : (conversa['outro_usuario_nome'] ?? 'Usuário'),
            ),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao iniciar conversa.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar mensagem: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTriangularList(List<MatchTriangular> matches) {
    if (matches.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Nenhuma combinação triangular encontrada para o filtro selecionado.')));
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        // Chama o widget MatchTriangularCard que agora está em seu próprio arquivo
        return MatchTriangularCard(match: match);
      },
    );
  }
}