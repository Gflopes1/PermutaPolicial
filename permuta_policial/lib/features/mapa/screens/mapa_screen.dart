// /lib/features/mapa/screens/mapa_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/mapa_provider.dart';
import '../../../core/models/ponto_mapa.dart';
import '../../../core/models/detalhe_municipio.dart';
import '../../../core/config/app_routes.dart';

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
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return FutureBuilder<List<DetalheMunicipio>>(
          future: provider.fetchMunicipioDetails(ponto.municipioId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(heightFactor: 5, child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(heightFactor: 5, child: Text('Erro: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(heightFactor: 5, child: Text('Nenhum detalhe encontrado.'));
            }
            final detalhes = snapshot.data!;
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Policiais ${provider.tipoVisualizacao == 'saindo' ? 'querendo sair' : 'querendo entrar'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: detalhes.length,
                      itemBuilder: (context, index) {
                        final detalhe = detalhes[index];
                        final hasQso = detalhe.qso != null && detalhe.qso!.isNotEmpty;
                        return ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(detalhe.policialNome),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${detalhe.forcaSigla} | ${detalhe.unidadeNome}'),
                              if (hasQso)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: detalhe.qso!));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Número copiado!'),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(Icons.phone, size: 14, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Text(
                                          detalhe.qso!,
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.copy, size: 12, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapaProvider>(
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
            // Trava o norte - não permite rotação do mapa
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
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