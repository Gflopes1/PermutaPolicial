// /lib/features/marketplace/screens/marketplace_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/marketplace_provider.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';
import '../../../core/config/app_routes.dart';
import '../widgets/marketplace_grid_item.dart';
import '../widgets/marketplace_filters_dialog.dart';
import 'marketplace_photo_picker_screen.dart';
import 'marketplace_meus_itens_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  
  String? _tipoFiltro;
  String? _estadoFiltro;
  String? _cidadeFiltro;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {}); // Atualiza a UI quando o texto da busca muda
  }

  void _loadData() {
    final provider = Provider.of<MarketplaceProvider>(context, listen: false);
    provider.loadItens(
      tipo: _tipoFiltro,
      search: _searchController.text.isEmpty ? null : _searchController.text,
      estado: _estadoFiltro,
      cidade: _cidadeFiltro,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 300) {
      final provider = Provider.of<MarketplaceProvider>(context, listen: false);
      if (!provider.isLoadingMore && provider.hasMoreItems) {
        provider.loadMoreItens();
      }
    }
  }

  void _abrirFiltros() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => MarketplaceFiltersDialog(
        tipoInicial: _tipoFiltro,
        estadoInicial: _estadoFiltro,
        cidadeInicial: _cidadeFiltro,
      ),
    );
    
    if (result != null) {
      setState(() {
        _tipoFiltro = result['tipo'];
        _estadoFiltro = result['estado'];
        _cidadeFiltro = result['cidade'];
      });
      _loadData();
    }
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_tipoFiltro != null) count++;
    if (_estadoFiltro != null) count++;
    if (_cidadeFiltro != null) count++;
    return count;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeFilters = _getActiveFiltersCount();
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Navega para o dashboard em vez de sair do app
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      },
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.store, color: theme.primaryColor),
            const SizedBox(width: 8),
            const Text('Marketplace'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(136),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.explore),
                    text: 'Explorar',
                  ),
                  Tab(
                    icon: Icon(Icons.inventory_2),
                    text: 'Meus Anúncios',
                  ),
                ],
              ),
              
              // Aviso de expiração
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.amber.shade50,
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Anúncios expiram automaticamente após 1 mês',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExplorarTab(theme, activeFilters),
          const MarketplaceMeusItensScreen(),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final user = Provider.of<DashboardProvider>(
            context, 
            listen: false,
          ).userData;
          
          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Você precisa estar logado para criar anúncios'),
              ),
            );
            return;
          }
          
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MarketplacePhotoPickerScreen(),
            ),
          );
          
          if (result == true) {
            _loadData();
          }
        },
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('Criar Anúncio'),
        backgroundColor: theme.primaryColor,
        elevation: 4,
      ),
      ),
    );
  }

  Widget _buildExplorarTab(ThemeData theme, int activeFilters) {
    return Column(
      children: [
        // Barra de busca e filtros
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar anúncios...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadData();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _loadData(),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Botão de filtros
              Stack(
                children: [
                  IconButton(
                    onPressed: _abrirFiltros,
                    icon: const Icon(Icons.tune),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  if (activeFilters > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '$activeFilters',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        
        // Grid de itens
        Expanded(
          child: Consumer<MarketplaceProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.itens.isEmpty) {
                return _buildLoadingGrid(theme);
              }

              if (provider.errorMessage != null) {
                return _buildErrorState(theme, provider.errorMessage!);
              }

              if (provider.itens.isEmpty) {
                return _buildEmptyState(theme);
              }

              return RefreshIndicator(
                onRefresh: () async => _loadData(),
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: provider.itens.length + (provider.isLoadingMore ? 2 : 0),
                  itemBuilder: (context, index) {
                    // Mostra indicador de carregamento nas últimas posições
                    if (index >= provider.itens.length) {
                      return Container(
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      );
                    }
                    return MarketplaceGridItem(
                      item: provider.itens[index],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingGrid(ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 20,
                      width: 100,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
              'Erro ao carregar anúncios',
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
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

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
              'Nenhum anúncio encontrado',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seja o primeiro a criar um anúncio!',
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

