// /lib/features/dashboard/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/dashboard_provider.dart';
import '../../../core/config/app_routes.dart';

// Repositórios e Exceções para o novo card
import '../../../core/api/api_exception.dart';
import '../../../core/api/repositories/novos_soldados_repository.dart';

// Widgets filhos
import '../widgets/boas_vindas_card.dart';
import '../../profile/widgets/minha_lotacao_card.dart';
import '../widgets/minhas_intencoes_card.dart';
import '../widgets/resultados_permuta_widget.dart';
import '../widgets/chat_card.dart';
import '../widgets/admin_forum_buttons.dart';
import '../widgets/parceiros_card.dart';
import '../widgets/mapa_card.dart';
import '../widgets/marketplace_card.dart';
import '../../../core/models/parceiro.dart';

// Modais
import '../../profile/widgets/edit_lotacao_modal.dart';
import '../../profile/widgets/gerir_intencoes_modal.dart';
import '../../profile/widgets/meus_dados_modal.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Estado local para o loading do botão do novo card
  bool _isCheckingAccess = false;

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

Future<void> _checkAccessAndNavigate() async {
  setState(() {
    _isCheckingAccess = true;
  });

  final repository = context.read<NovosSoldadosRepository>();
  
  try {
    // 🔍 Verifique se o usuário está autenticado
    final provider = context.read<DashboardProvider>();
    if (provider.userData == null) {
      throw ApiException(message: 'Usuário não autenticado');
    }
    
    await repository.checkAccess();
    
    if (!mounted) return;
    
    Navigator.of(context).pushNamed(
      AppRoutes.novosSoldadosEscolha,
    );

  } on ApiException catch (e) {
    if (!mounted) return;
    
    // 📝 Mensagem mais amigável para erro de autenticação
    String message = e.message;
    if (e.statusCode == 401 || e.statusCode == 403) {
      message = 'Você não tem permissão para acessar esta funcionalidade. '
                'Certifique-se de estar logado com e-mail funcional da Microsoft.';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro desconhecido: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isCheckingAccess = false;
      });
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
                icon: const Icon(Icons.person_outline),
                tooltip: 'Meus Dados',
                onPressed: () {
                  final provider = Provider.of<DashboardProvider>(context, listen: false);
                  if (provider.userData != null) {
                    showDialog(
                      context: context,
                      builder: (ctx) => ChangeNotifierProvider.value(
                        value: provider,
                        child: MeusDadosModal(
                          userProfile: provider.userData!,
                          intencoes: provider.intencoes,
                        ),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: 'Ajuda',
                onPressed: () => _launchURL('https://br.permutapolicial.com.br/help.html'),
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

  Widget _buildNovosSoldadosCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Escolha de Vagas - Novos Soldados', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Simule 3 opções de escolha de OPM com base na sua classificação no curso.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.primaryColor.withAlpha(122))
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Acesso somente utilizando login via e-mail funcional (Microsoft).',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isCheckingAccess ? null : _checkAccessAndNavigate, 
              child: _isCheckingAccess
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('ACESSAR AMBIENTE'),
            )
          ],
        ),
      ),
    );
  }

  // Layout Mobile com nova ordem
  Widget _buildMobileLayout(DashboardProvider provider) {
    final perfilIncompleto = provider.userData?.unidadeAtualNome == null;
    return RefreshIndicator(
      onRefresh: () => provider.fetchInitialData(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          // Boas-vindas (se perfil incompleto)
          if (perfilIncompleto) 
            BoasVindasCard(
              onCompletarPerfil: () => Navigator.of(context).pushNamed(AppRoutes.completarPerfil),
            ),
          if (perfilIncompleto) const SizedBox(height: 16),
          
          // 1. Minha Lotação Atual (compacta)
          if (provider.userData != null)
            _buildMinhaLotacaoCompacta(provider),
          if (provider.userData != null) const SizedBox(height: 16),

          // Card de Anunciantes (entre lotação e marketplace)
          if (provider.exibirCardParceiros && provider.parceiros.isNotEmpty)
            ParceirosCard(parceiros: provider.parceiros.map((p) => Parceiro.fromJson(p)).toList()),
          if (provider.exibirCardParceiros && provider.parceiros.isNotEmpty) const SizedBox(height: 16),
          
          // 2. Marketplace
          const MarketplaceCard(),
          const SizedBox(height: 16),
          
          // 3. Fórum e Admin
          if (provider.userData != null)
            AdminForumButtons(isEmbaixador: provider.userData!.isEmbaixador),
          if (provider.userData != null) const SizedBox(height: 16),
          
          // 4. Minhas Intenções de Destino
          MinhasIntencoesCard(
            intencoes: provider.intencoes,
            onEdit: _showEditIntencoesModal,
          ),
          const SizedBox(height: 16),
          
          // 5. Resultados da Busca
          _buildMatchesSection(provider),
          const SizedBox(height: 16),
          
          // 6. Mapa
          const MapaCard(),
          const SizedBox(height: 16),
          
          // 7. Mensagens
          const ChatCard(),
          const SizedBox(height: 16),
          
          // 8. Escolha de Vagas
          _buildNovosSoldadosCard(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Widget compacto para Minha Lotação
  Widget _buildMinhaLotacaoCompacta(DashboardProvider provider) {
    final userData = provider.userData!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Minha Lotação Atual',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: _showEditLotacaoModal,
                  tooltip: 'Editar',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              userData.unidadeAtualNome ?? 'Não informado',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${userData.municipioAtualNome ?? ''}, ${userData.estadoAtualSigla ?? ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(DashboardProvider provider) {
    final perfilIncompleto = provider.userData?.unidadeAtualNome == null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- BARRA LATERAL (ESQUERDA) ---
        SizedBox(
          width: 380,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              if (provider.userData != null)
                MinhaLotacaoCard(
                  userProfile: provider.userData!,
                  onEdit: _showEditLotacaoModal,
                ),
              if (provider.userData != null) const SizedBox(height: 20),
            
              _buildNovosSoldadosCard(context),
              const SizedBox(height: 20),

              MinhasIntencoesCard(
                intencoes: provider.intencoes,
                onEdit: _showEditIntencoesModal,
              ), 
              const SizedBox(height: 20),
            
              const MarketplaceCard(),
              const SizedBox(height: 20),
              const ChatCard(), 
              const SizedBox(height: 20),
            
              if (provider.userData != null)
                AdminForumButtons(isEmbaixador: provider.userData!.isEmbaixador),
              if (provider.userData != null) const SizedBox(height: 20),
            
              if (provider.exibirCardParceiros && provider.parceiros.isNotEmpty)
                ParceirosCard(parceiros: provider.parceiros.map((p) => Parceiro.fromJson(p)).toList()),
              if (provider.exibirCardParceiros && provider.parceiros.isNotEmpty) const SizedBox(height: 20),
            ],
          ),
        ),
        
        const VerticalDivider(width: 1, thickness: 1),
        
        // --- CONTEÚDO PRINCIPAL (DIREITA) ---
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.fetchInitialData(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              children: [
                if (perfilIncompleto)
                  BoasVindasCard(
                    onCompletarPerfil: () => Navigator.of(context).pushNamed(AppRoutes.completarPerfil),
                  ),
                if (perfilIncompleto) const SizedBox(height: 20),
              
                _buildMatchesSection(provider), 
                const SizedBox(height: 20),
              
                const MarketplaceCard(),
                const SizedBox(height: 20),
                const MapaCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}