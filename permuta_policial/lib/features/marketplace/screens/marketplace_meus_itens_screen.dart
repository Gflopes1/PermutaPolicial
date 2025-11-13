// /lib/features/marketplace/screens/marketplace_meus_itens_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/marketplace_provider.dart';
import '../../../core/models/marketplace_item.dart';
import '../../../core/api/api_client.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';
import 'marketplace_create_screen.dart';
import 'marketplace_detail_screen.dart';

class MarketplaceMeusItensScreen extends StatefulWidget {
  const MarketplaceMeusItensScreen({super.key});

  @override
  State<MarketplaceMeusItensScreen> createState() => _MarketplaceMeusItensScreenState();
}

class _MarketplaceMeusItensScreenState extends State<MarketplaceMeusItensScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarItens();
    });
  }

  void _carregarItens() {
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final user = dashboardProvider.userData;
    if (user != null) {
      final provider = Provider.of<MarketplaceProvider>(context, listen: false);
      provider.loadMeusItens(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final baseUrl = apiClient.baseUrl;

    return Consumer<MarketplaceProvider>(
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

        if (provider.meusItens.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Você ainda não criou nenhum anúncio.'),
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

        return RefreshIndicator(
          onRefresh: () async => _carregarItens(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.meusItens.length,
            itemBuilder: (context, index) {
              final item = provider.meusItens[index];
              return _buildItemCard(context, item, baseUrl, provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildItemCard(BuildContext context, MarketplaceItem item, String baseUrl, MarketplaceProvider provider) {
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
                      color: item.status == 'APROVADO'
                          ? Colors.green.shade100
                          : item.status == 'REJEITADO'
                              ? Colors.red.shade100
                              : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.statusLabel,
                      style: TextStyle(
                        color: item.status == 'APROVADO'
                            ? Colors.green.shade700
                            : item.status == 'REJEITADO'
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            if (item.fotos.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  '$baseUrl${item.fotos[0]}',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 64),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'R\$ ${item.valor.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MarketplaceCreateScreen(itemToEdit: item),
                      ),
                    );
                    if (result == true && mounted) {
                      _carregarItens();
                    }
                  },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Excluir', style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirmar exclusão'),
                        content: const Text('Deseja realmente excluir este anúncio?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Excluir'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && mounted) {
                      final success = await provider.deleteItem(item.id);
                      if (!mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Anúncio excluído!')),
                        );
                        _carregarItens();
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

