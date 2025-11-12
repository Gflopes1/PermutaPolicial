// /lib/features/admin/screens/admin_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../widgets/estatisticas_tab.dart';
import '../widgets/usuarios_tab.dart';
import '../widgets/parceiros_tab.dart';
import '../widgets/verificacoes_tab.dart';
import '../widgets/sugestoes_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      provider.loadEstatisticas();
      provider.loadPoliciais();
      provider.loadVerificacoes();
      provider.loadSugestoes();
      provider.loadParceiros();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Administração'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Estatísticas'),
            Tab(icon: Icon(Icons.people), text: 'Usuários'),
            Tab(icon: Icon(Icons.business), text: 'Parceiros'),
            Tab(icon: Icon(Icons.verified_user), text: 'Verificações'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Sugestões'),
          ],
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.estatisticas == null) {
            return const LoadingWidget(message: 'Carregando dados...');
          }

          return TabBarView(
            controller: _tabController,
            children: [
              EstatisticasTab(provider: provider),
              UsuariosTab(provider: provider),
              ParceirosTab(provider: provider),
              VerificacoesTab(provider: provider),
              SugestoesTab(provider: provider),
            ],
          );
        },
      ),
    );
  }
}

