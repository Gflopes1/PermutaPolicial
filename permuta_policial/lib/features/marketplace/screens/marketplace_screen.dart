// /lib/features/marketplace/screens/marketplace_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/marketplace_provider.dart';
import 'marketplace_list_screen.dart';
import 'marketplace_create_screen.dart';
import 'marketplace_meus_itens_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _tipoFiltro;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MarketplaceProvider>(context, listen: false);
      provider.loadItens();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Column(
            children: [
              TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.store), text: 'Itens'),
            Tab(icon: Icon(Icons.inventory), text: 'Meus Itens'),
          ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: Colors.orange.shade50,
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Anúncios expiram após 1 mês',
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MarketplaceCreateScreen()),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MarketplaceListScreen(
            tipoFiltro: _tipoFiltro,
            searchController: _searchController,
          ),
          const MarketplaceMeusItensScreen(),
        ],
      ),
    );
  }
}

