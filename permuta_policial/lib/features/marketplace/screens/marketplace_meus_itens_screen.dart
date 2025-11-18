// /lib/features/marketplace/screens/marketplace_meus_itens_screen.dart
// (Refatorado para usar layout em grade e corrigir fluxo de edição)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/marketplace_provider.dart';
import '../../../core/models/marketplace_item.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';
import '../widgets/marketplace_grid_item.dart'; // O novo card do grid
import 'marketplace_create_form_screen.dart'; // Para edição direta

class MarketplaceMeusItensScreen extends StatefulWidget {
  const MarketplaceMeusItensScreen({super.key});

  @override
  State<MarketplaceMeusItensScreen> createState() =>
      _MarketplaceMeusItensScreenState();
}

class _MarketplaceMeusItensScreenState
    extends State<MarketplaceMeusItensScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarItens();
    });
  }

  Future<void> _carregarItens() async {
    final dashboardProvider =
        Provider.of<DashboardProvider>(context, listen: false);
    final user = dashboardProvider.userData;
    if (user != null) {
      final provider =
          Provider.of<MarketplaceProvider>(context, listen: false);
      // O provider já tem um _isLoadingMeusItens, mas vamos usar o _isLoading padrão
      // por consistência com o provider refatorado.
      await provider.loadMeusItens(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<MarketplaceProvider>(
      builder: (context, provider, child) {
        // Usando o isLoading do provider
        if (provider.isLoading && provider.meusItens.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && provider.meusItens.isEmpty) {
          return _buildErrorState(theme, provider.errorMessage!);
        }

        if (provider.meusItens.isEmpty) {
          return _buildEmptyState(theme);
        }

        return RefreshIndicator(
          onRefresh: _carregarItens,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.70, // Mesmo aspect ratio da outra tela
            ),
            itemCount: provider.meusItens.length,
            itemBuilder: (context, index) {
              final item = provider.meusItens[index];
              return Stack(
                children: [
                  // 1. O Card Base
                  MarketplaceGridItem(item: item),
                  // 2. O Overlay com ações e status
                  _buildItemOverlay(context, theme, item, provider),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Cria o overlay com status e botões de ação
  Widget _buildItemOverlay(
    BuildContext context,
    ThemeData theme,
    MarketplaceItem item,
    MarketplaceProvider provider,
  ) {
    Color statusColor;
    String statusLabel = item.statusLabel;

    switch (item.status) {
      case 'APROVADO':
        statusColor = Colors.green;
        break;
      case 'REJEITADO':
        statusColor = theme.colorScheme.error;
        break;
      case 'PENDENTE':
      default:
        statusColor = Colors.orange;
        break;
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Overlay para escurecer
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(89), // 35%
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          // Status Chip
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(204), // 80%
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Botões de Ação
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: theme.cardColor.withAlpha(230), // 90%
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, size: 20, color: theme.colorScheme.onSurface),
                    tooltip: 'Editar',
                    onPressed: () async {
                      // Navega direto para o formulário de edição
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MarketplaceCreateFormScreen(
                            itemToEdit: item, // Passa o item para edição
                          ),
                        ),
                      );
                      // Se o usuário salvou (retornou true), recarrega a lista
                      if (result == true && mounted) {
                        _carregarItens();
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: theme.colorScheme.error, size: 20),
                    tooltip: 'Excluir',
                    onPressed: () => _confirmarExclusao(context, provider, item.id),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Popup de confirmação para exclusão
  Future<void> _confirmarExclusao(
      BuildContext context, MarketplaceProvider provider, int id) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir este anúncio? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final success = await provider.deleteItem(id);
      
      // CORREÇÃO: Passando `isError`
      if (success) {
        _showMessage('Anúncio excluído!', isError: false);
        _carregarItens(); // Recarrega a lista
      } else {
        _showMessage(provider.errorMessage ?? 'Erro ao excluir.', isError: true);
      }
    }
  }

  /// Exibe um SnackBar
  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Widget para estado de erro
  Widget _buildErrorState(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar seus anúncios',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _carregarItens,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget para estado vazio
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Você não publicou anúncios',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use o botão (+) para criar seu primeiro anúncio.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}