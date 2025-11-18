// /lib/features/mapa/screens/mapa_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/mapa_provider.dart';
import '../../../core/models/ponto_mapa.dart';
import '../../../core/models/detalhe_municipio.dart';
import '../../../core/config/app_routes.dart';
import '../../notificacoes/providers/notificacoes_provider.dart';
import '../../chat/providers/chat_provider.dart';
import '../../chat/screens/chat_conversa_screen.dart';

class MapaScreen extends StatefulWidget {
  final bool isVisitorMode;

  const MapaScreen({super.key, this.isVisitorMode = false});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Pede ao provider para carregar os dados iniciais (filtros e mapa)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MapaProvider>(context, listen: false).fetchInitialData();
    });
  }

  void _resetMapView() {
    _mapController.move(const LatLng(-14.2350, -51.9253), 4.5);
  }

  Future<void> _solicitarContato(BuildContext context, int policialId) async {
    final notificacoesProvider = Provider.of<NotificacoesProvider>(context, listen: false);
    final success = await notificacoesProvider.criarSolicitacaoContato(policialId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? 'Solicitação de contato enviada com sucesso!' 
            : notificacoesProvider.errorMessage ?? 'Erro ao enviar solicitação.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
  
  Future<void> _enviarMensagem(BuildContext context, int destinatarioId, bool isAnonima) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    try {
      // Inicializa o socket se necessário
      await chatProvider.initializeSocket();
      
      // Inicia a conversa (anônima se especificado)
      final conversa = await chatProvider.iniciarConversa(destinatarioId, anonima: isAnonima);
      
      if (conversa != null && mounted) {
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
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao iniciar conversa.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar mensagem: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Mostra um modal de login para visitantes
  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.lock_outline), SizedBox(width: 12), Text('Funcionalidade Exclusiva')]),
        content: const Text('Para ver os detalhes dos policiais, você precisa criar uma conta ou fazer login.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Continuar Navegando')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacementNamed(AppRoutes.auth);
            },
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Fazer Login'),
          ),
        ],
      ),
    );
  }

  // Mostra os detalhes do município em um BottomSheet
  void _showDetalhesModal(BuildContext context, PontoMapa ponto) async {
    final provider = Provider.of<MapaProvider>(context, listen: false);
    final tipo = provider.tipoVisualizacao;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FutureBuilder<List<DetalheMunicipio>>(
          future: provider.fetchMunicipioDetails(ponto.municipioId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Erro: ${snapshot.error}'),
                    ],
                  ),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 48),
                      SizedBox(height: 16),
                      Text('Nenhum detalhe encontrado.'),
                    ],
                  ),
                ),
              );
            }
            final detalhes = snapshot.data!;
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        tipo == 'saindo' 
                          ? 'Policiais querendo sair de ${ponto.nome}'
                          : tipo == 'vindo'
                            ? 'Policiais querendo vir para ${ponto.nome}'
                            : 'Detalhes de ${ponto.nome}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: detalhes.length,
                        itemBuilder: (context, index) {
                          final detalhe = detalhes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          detalhe.ocultarNoMapa ? 'Usuário não identificado' : detalhe.policialNome,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (detalhe.ocultarNoMapa) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.orange.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.info_outline, size: 20, color: Colors.orange.shade700),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Este usuário optou por não aparecer no mapa. A mensagem será anônima até que ele responda.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.orange.shade900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () => _enviarMensagem(context, detalhe.policialId, true),
                                                  icon: const Icon(Icons.message, size: 18),
                                                  label: const Text('Enviar Mensagem'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () => _solicitarContato(context, detalhe.policialId),
                                                  icon: const Icon(Icons.person_add, size: 18),
                                                  label: const Text('Solicitar Contato'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.orange.shade700,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    // Só mostra telefone e botões se o usuário não estiver oculto
                                    const SizedBox(height: 12),
                                    if (detalhe.qso != null && detalhe.qso!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.phone, size: 20, color: Colors.green),
                                            const SizedBox(width: 8),
                                            SelectableText(
                                              detalhe.qso!,
                                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _enviarMensagem(context, detalhe.policialId, false),
                                            icon: const Icon(Icons.message, size: 18),
                                            label: const Text('Enviar Mensagem'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _solicitarContato(context, detalhe.policialId),
                                            icon: const Icon(Icons.person_add, size: 18),
                                            label: const Text('Solicitar Contato'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context).colorScheme.primary,
                                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const Divider(),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on, size: 20, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Onde está:',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            Text(
                                              detalhe.municipioAtual != null && detalhe.estadoAtual != null
                                                ? '${detalhe.municipioAtual}, ${detalhe.estadoAtual}'
                                                : detalhe.unidadeNome ?? 'Não informado',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                            if (detalhe.unidadeNome != null)
                                              Text(
                                                detalhe.unidadeNome!,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        tipo == 'saindo' ? Icons.arrow_upward : Icons.arrow_downward,
                                        size: 20,
                                        color: tipo == 'saindo' ? Colors.orange : Colors.blue,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tipo == 'saindo' ? 'Quer sair para:' : 'Quer vir para:',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            if (tipo == 'saindo' && detalhe.destinosDesejados != null)
                                              Text(
                                                detalhe.destinosDesejados!,
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              )
                                            else if (tipo == 'vindo' && detalhe.municipioDesejado != null)
                                              Text(
                                                '${detalhe.municipioDesejado}, ${detalhe.estadoDesejado ?? ""}',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              )
                                            else
                                              const Text('Não especificado'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Chip(
                                    label: Text(detalhe.forcaSigla),
                                    avatar: const Icon(Icons.shield, size: 18),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Volta para a tela anterior
        Navigator.of(context).pop();
      },
      child: Consumer<MapaProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Mapa de Exploração'),
              leading: widget.isVisitorMode ? IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()) : null,
              actions: [
                IconButton(icon: const Icon(Icons.my_location), tooltip: 'Centralizar Mapa', onPressed: _resetMapView),
                IconButton(icon: const Icon(Icons.filter_alt), tooltip: 'Filtros', onPressed: () => _showFilterPanel(context)),
              ],
            ),
            body: _buildBody(provider),
          );
        },
      ),
    );
  }

  Widget _buildBody(MapaProvider provider) {
    if (provider.isInitialDataLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return Center(child: Text('Erro: ${provider.errorMessage}'));
    }

    final markers = provider.pontosDoMapa.map((ponto) {
      String label = (provider.tipoVisualizacao == 'balanco' ? ponto.balanco?.toString() : ponto.contagem.toString()) ?? '0';
      if (provider.tipoVisualizacao == 'balanco' && (ponto.balanco ?? 0) > 0) label = '+$label';
      
      return Marker(
        point: LatLng(ponto.latitude, ponto.longitude),
        width: 60, height: 60,
        child: GestureDetector(
          onTap: () {
            if (widget.isVisitorMode) {
              _showLoginPrompt();
            } else {
              _showDetalhesModal(context, ponto);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: _getMarkerColor(provider.tipoVisualizacao, ponto),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
          ),
        ),
      );
    }).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(-14.2350, -51.9253),
            initialZoom: 4.5,
            minZoom: 3.0,
            maxZoom: 18.0,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // Desabilita rotação (trava norte)
            ),
          ),
          children: [
            TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 80, size: const Size(50, 50),
                markers: markers,
                builder: (context, markers) {
                  return Container(
                    decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                    child: Center(child: Text(markers.length.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  );
                },
              ),
            ),
          ],
        ),
        if (provider.isLoading) Container(color: Colors.black.withAlpha(102), child: const Center(child: CircularProgressIndicator())),
        _buildLegend(provider.tipoVisualizacao),
      ],
    );
  }

  void _showFilterPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _buildFilterContent(),
    );
  }

  Widget _buildFilterContent() {
    // Usamos um Consumer aqui para garantir que o conteúdo do modal também se reconstrua
    return Consumer<MapaProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
              const Divider(height: 24),
              const Text('Tipo de Visualização', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  FilterChip(label: const Text('Saindo'), selected: provider.tipoVisualizacao == 'saindo', onSelected: (_) => provider.setTipoVisualizacao('saindo')),
                  FilterChip(label: const Text('Vindo'), selected: provider.tipoVisualizacao == 'vindo', onSelected: (_) => provider.setTipoVisualizacao('vindo')),
                  FilterChip(label: const Text('Balanço'), selected: provider.tipoVisualizacao == 'balanco', onSelected: (_) => provider.setTipoVisualizacao('balanco')),
                ],
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<int?>(
                initialValue: provider.estadoSelecionado,
                decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Todos os Estados')),
                  ...provider.estados.map((e) => DropdownMenuItem<int?>(value: e.id, child: Text(e.sigla))),
                ],
                onChanged: (value) => provider.setEstado(value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: provider.forcaSelecionada,
                decoration: const InputDecoration(labelText: 'Força Policial', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Todas as Forças')),
                  ...provider.forcas.map((f) => DropdownMenuItem<int?>(value: f.id, child: Text(f.sigla))),
                ],
                onChanged: (value) => provider.setForca(value),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => provider.limparFiltros(), child: const Text('Limpar Filtros'))),
            ],
          ),
        );
      },
    );
  }

  Color _getMarkerColor(String tipo, PontoMapa? ponto) {
    if (tipo == 'saindo') return Colors.redAccent;
    if (tipo == 'vindo') return Colors.blueAccent;
    if (tipo == 'balanco') return (ponto?.balanco ?? 0) >= 0 ? Colors.green : Colors.orange;
    return Colors.grey;
  }

  Widget _buildLegend(String tipo) {
    Widget legendContent;

    switch (tipo) {
      case 'saindo':
        legendContent = _buildLegendRow(
          icon: Icons.arrow_upward,
          color: Colors.redAccent,
          text: 'Policiais querendo sair do município',
        );
        break;
      case 'vindo':
        legendContent = _buildLegendRow(
          icon: Icons.arrow_downward,
          color: Colors.blueAccent,
          text: 'Policiais querendo entrar no município',
        );
        break;
      case 'balanco':
        legendContent = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendRow(
              icon: Icons.add_circle,
              color: Colors.green,
              text: 'Balanço positivo (mais entradas que saídas)',
            ),
            const SizedBox(height: 4),
            _buildLegendRow(
              icon: Icons.remove_circle,
              color: Colors.orange,
              text: 'Balanço negativo (mais saídas que entradas)',
            ),
          ],
        );
        break;
      default:
        return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: legendContent,
          ),
        ),
      ),
    );
  }

  // Função auxiliar para construir as linhas da legenda
  Widget _buildLegendRow({required IconData icon, required Color color, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}