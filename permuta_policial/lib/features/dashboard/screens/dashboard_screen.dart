// /lib/features/dashboard/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/dashboard_provider.dart';
import '../../../core/config/app_routes.dart';

// Widgets filhos
import '../widgets/boas_vindas_card.dart';
import '../../profile/widgets/minha_lotacao_card.dart';
import '../widgets/minhas_intencoes_card.dart';
import '../widgets/resultados_permuta_widget.dart';
import '../widgets/chat_card.dart';
import '../widgets/admin_forum_buttons.dart';
import '../widgets/parceiros_card.dart';
import '../widgets/mapa_card.dart';

// Modais
import '../../profile/widgets/edit_lotacao_modal.dart';
import '../../profile/widgets/gerir_intencoes_modal.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchInitialData();
    });
  }

  void _showEditLotacaoModal() {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    if (provider.userData == null) return;
    showDialog(
      context: context,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: provider,
        child: EditLotacaoModal(userProfile: provider.userData!),
      ),
    );
  }
  
  void _showEditIntencoesModal() {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: provider,
        child: const GerirIntencoesModal(),
      ),
    );
  }
  
  Future<void> _logout() async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    await provider.logout();
    navigator.pushReplacementNamed(AppRoutes.auth);
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o link.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(provider.userData?.nome ?? 'Painel'),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: 'Ajuda',
                onPressed: () => _launchURL('https://brasil.permutapolicial.com.br/help.html'),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sair',
                onPressed: _logout,
              ),
            ],
          ),
          body: _buildBody(context, provider),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, DashboardProvider provider) {
    if (provider.isLoadingInitialData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.initialDataError != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Erro ao carregar dados', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(provider.initialDataError!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => provider.fetchInitialData(),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
      ));
    }
    if (provider.userData == null) {
      return const Center(child: Text('Não foi possível carregar os dados do usuário.'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return _buildMobileLayout(provider);
        } else {
          return _buildDesktopLayout(provider);
        }
      },
    );
  }

  Widget _buildMatchesSection(DashboardProvider provider) {
    if (provider.userData?.unidadeAtualNome == null) return const SizedBox.shrink();
    if (provider.isLoadingMatches) {
      return const Card(child: Center(heightFactor: 5, child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Buscando permutas...')])));
    }
    if (provider.matchesError != null) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            const Icon(Icons.warning_amber_rounded), const SizedBox(height: 8),
            const Text('Erro ao buscar permutas', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8),
            Text(provider.matchesError!, textAlign: TextAlign.center), const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: () => provider.fetchMatches(), icon: const Icon(Icons.refresh), label: const Text('Tentar Novamente'))
          ]),
        ),
      );
    }
    if (provider.matches != null) {
      return ResultadosPermutaWidget(results: provider.matches!);
    }
    return const SizedBox.shrink();
  }

  Widget _buildMobileLayout(DashboardProvider provider) {
    final perfilIncompleto = provider.userData?.unidadeAtualNome == null;
    return RefreshIndicator(
      onRefresh: () => provider.fetchInitialData(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          if (perfilIncompleto) BoasVindasCard(onCompletarPerfil: () => Navigator.of(context).pushNamed(AppRoutes.completarPerfil)),
          if (perfilIncompleto) const SizedBox(height: 16),
          MinhaLotacaoCard(userProfile: provider.userData!, onEdit: _showEditLotacaoModal),
          const SizedBox(height: 16),
          MinhasIntencoesCard(intencoes: provider.intencoes, onEdit: _showEditIntencoesModal),
          const SizedBox(height: 16),
          _buildMatchesSection(provider),
          const SizedBox(height: 16),
          const MapaCard(), const SizedBox(height: 16),
          const ChatCard(), const SizedBox(height: 16),
          AdminForumButtons(isEmbaixador: provider.userData!.isEmbaixador), const SizedBox(height: 16),
          const ParceirosCard(parceiros: [],),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(DashboardProvider provider) {
    final perfilIncompleto = provider.userData?.unidadeAtualNome == null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 380, child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          children: [
            MinhaLotacaoCard(userProfile: provider.userData!, onEdit: _showEditLotacaoModal), const SizedBox(height: 20),
            MinhasIntencoesCard(intencoes: provider.intencoes, onEdit: _showEditIntencoesModal), const SizedBox(height: 20),
            const ChatCard(), const SizedBox(height: 20),
            AdminForumButtons(isEmbaixador: provider.userData!.isEmbaixador), const SizedBox(height: 20),
            const ParceirosCard(parceiros: [],),
          ],
        )),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: RefreshIndicator(
          onRefresh: () => provider.fetchInitialData(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              if (perfilIncompleto) BoasVindasCard(onCompletarPerfil: () => Navigator.of(context).pushNamed(AppRoutes.completarPerfil)),
              if (perfilIncompleto) const SizedBox(height: 20),
              _buildMatchesSection(provider), const SizedBox(height: 20),
              const MapaCard(),
            ],
          ),
        )),
      ],
    );
  }
}