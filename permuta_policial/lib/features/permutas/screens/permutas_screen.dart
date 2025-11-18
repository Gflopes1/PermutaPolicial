// /lib/features/permutas/screens/permutas_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/minhas_intencoes_card.dart';
import '../../dashboard/widgets/resultados_permuta_widget.dart';
import '../../profile/widgets/gerir_intencoes_modal.dart';

class PermutasScreen extends StatefulWidget {
  const PermutasScreen({super.key});

  @override
  State<PermutasScreen> createState() => _PermutasScreenState();
}

class _PermutasScreenState extends State<PermutasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      provider.fetchInitialData();
      if (provider.userData?.unidadeAtualNome != null) {
        provider.fetchMatches();
      }
    });
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ambiente de Permutas'),
        ),
        body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingInitialData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.initialDataError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  const Text('Erro ao carregar dados'),
                  const SizedBox(height: 8),
                  Text(provider.initialDataError!),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.fetchInitialData(),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          final perfilIncompleto = provider.userData?.unidadeAtualNome == null;

          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchInitialData();
              if (provider.userData?.unidadeAtualNome != null) {
                await provider.fetchMatches();
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (perfilIncompleto)
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer.withAlpha(26),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'Complete seu perfil',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Para ver suas combinações de permuta, você precisa definir sua lotação atual.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (perfilIncompleto) const SizedBox(height: 16),

                // Minhas Intenções
                MinhasIntencoesCard(
                  intencoes: provider.intencoes,
                  onEdit: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => ChangeNotifierProvider.value(
                        value: provider,
                        child: const GerirIntencoesModal(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Resultados da Busca
                if (!perfilIncompleto && provider.matches != null)
                  _buildMatchesSection(provider),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildMatchesSection(DashboardProvider provider) {
    if (provider.isLoadingMatches) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (provider.matchesError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              const Text('Erro ao carregar combinações'),
              const SizedBox(height: 8),
              Text(provider.matchesError!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.fetchMatches(),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final matches = provider.matches;
    if (matches == null) {
      return const SizedBox.shrink();
    }

    final totalMatches = matches.diretas.length + 
                        matches.interessados.length + 
                        matches.triangulares.length;

    if (totalMatches == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Nenhuma combinação encontrada',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Adicione intenções de permuta para encontrar combinações.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ResultadosPermutaWidget(results: matches);
  }
}

