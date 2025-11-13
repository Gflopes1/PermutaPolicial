// /lib/features/marketplace/screens/marketplace_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/marketplace_provider.dart';
import '../../../core/models/marketplace_item.dart';
import '../../../core/api/api_client.dart';
import 'marketplace_detail_screen.dart';

class MarketplaceListScreen extends StatefulWidget {
  final String? tipoFiltro;
  final TextEditingController searchController;

  const MarketplaceListScreen({
    super.key,
    this.tipoFiltro,
    required this.searchController,
  });

  @override
  State<MarketplaceListScreen> createState() => _MarketplaceListScreenState();
}

class _MarketplaceListScreenState extends State<MarketplaceListScreen> {
  String? _tipoSelecionado;

  @override
  void initState() {
    super.initState();
    _tipoSelecionado = widget.tipoFiltro;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarItens();
    });
  }

  void _carregarItens() {
    final provider = Provider.of<MarketplaceProvider>(context, listen: false);
    provider.loadItens(
      tipo: _tipoSelecionado,
      search: widget.searchController.text.isEmpty ? null : widget.searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final baseUrl = apiClient.baseUrl;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: widget.searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _carregarItens(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _tipoSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todos')),
                        DropdownMenuItem(value: 'armas', child: Text('Armas')),
                        DropdownMenuItem(value: 'veiculos', child: Text('Veículos')),
                        DropdownMenuItem(value: 'equipamentos', child: Text('Equipamentos')),
                      ],
                      onChanged: (value) {
                        setState(() => _tipoSelecionado = value);
                        _carregarItens();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _carregarItens,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer<MarketplaceProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(provider.errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarItens,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                );
              }

              if (provider.itens.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Nenhum item encontrado.'),
                      SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Lembre-se: os anúncios são excluídos automaticamente após 1 mês da postagem.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.itens.length,
                itemBuilder: (context, index) {
                  final item = provider.itens[index];
                  return _buildItemCard(context, item, baseUrl);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, MarketplaceItem item, String baseUrl) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MarketplaceDetailScreen(item: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.fotos.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    '$baseUrl${item.fotos[0]}',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 64),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.titulo,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withAlpha(10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.tipoLabel,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'R\$ ${item.valor.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.descricao,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (item.policialNome != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Vendedor: ${item.policialNome}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

