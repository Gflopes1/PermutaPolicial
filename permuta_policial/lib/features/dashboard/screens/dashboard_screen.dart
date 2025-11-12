// /lib/features/dashboard/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/dashboard_provider.dart';
import '../../../core/config/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../shared/widgets/error_display_widget.dart';

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

// Modais
import '../../profile/widgets/edit_lotacao_modal.dart';
import '../../profile/widgets/gerir_intencoes_modal.dart';

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Saída'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      final navigator = Navigator.of(context);
      await provider.logout();
      if (mounted) {
        navigator.pushReplacementNamed(AppRoutes.auth);
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o link.')));
      }
    }
  }

  // ==========================================================
  // NOVA FUNÇÃO
  // Lógica para verificar o acesso ao módulo de Novos Soldados
  // ==========================================================
  Future<void> _checkAccessAndNavigate() async {
    setState(() {
      _isCheckingAccess = true;
    });

    // Usamos context.read pois estamos dentro de um callback
    final repository = context.read<NovosSoldadosRepository>();
    
    try {
      // 1. Tenta aceder à rota protegida
      await repository.checkAccess();
      
      // 2. Se deu 200 OK (passou nos pré-requisitos)
      if (!mounted) return;
      
      // Navega para a tela de escolha
      Navigator.of(context).pushNamed(
        AppRoutes.novosSoldadosEscolha,
      );

    } on ApiException catch (e) {
      // 3. Se deu erro (401 ou 403), o backend envia a mensagem de erro
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(ErrorMessageHelper.getFriendlyMessage(e)),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: AppConstants.snackBarDurationLong,
        ),
      );
    } catch (e) {
      // Erro genérico
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Erro desconhecido: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: AppConstants.snackBarDurationLong,
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
                icon: const Icon(Icons.person),
                tooltip: 'Meus Dados',
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.meusDados),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando dados...'),
          ],
        ),
      );
    }
    if (provider.initialDataError != null) {
      return ErrorDisplayWidget(
        customMessage: provider.initialDataError!,
        customTitle: 'Erro ao carregar dados',
        customIcon: Icons.cloud_off,
        onRetry: () => provider.fetchInitialData(),
      );
    }
    if (provider.userData == null) {
      return ErrorDisplayWidget(
        customMessage: 'Não foi possível carregar os dados do usuário.',
        customTitle: 'Erro',
        customIcon: Icons.person_off,
        onRetry: () => provider.fetchInitialData(),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppConstants.tabletBreakpoint) {
          return _buildMobileLayout(provider);
        } else if (constraints.maxWidth < AppConstants.desktopBreakpoint) {
          return _buildTabletLayout(provider);
        } else {
          return _buildDesktopLayout(provider);
        }
      },
    );
  }

  Widget _buildMatchesSection(DashboardProvider provider) {
    if (provider.userData?.unidadeAtualNome == null) return const SizedBox.shrink();
    if (provider.isLoadingMatches) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLG),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppConstants.spacingMD),
                Text(
                  'Buscando permutas...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (provider.matchesError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMD),
          child: ErrorDisplayWidget(
            customMessage: provider.matchesError!,
            customTitle: 'Erro ao buscar permutas',
            customIcon: Icons.warning_amber_rounded,
            compact: true,
            onRetry: () => provider.fetchMatches(),
          ),
        ),
      );
    }
    if (provider.matches != null) {
      return ResultadosPermutaWidget(results: provider.matches!);
    }
    return const SizedBox.shrink();
  }

  // ==========================================================
  // NOVO WIDGET
  // O card para o simulador de novos soldados
  // ==========================================================
  Widget _buildNovosSoldadosCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sim_card_outlined,
                  color: theme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: AppConstants.spacingSM),
                Expanded(
                  child: Text(
                    'Simulador de Vagas (Novos Soldados)',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSM),
            Text(
              'Simule suas 3 opções de escolha de OPM com base na sua classificação no curso.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMD),
            // Caixa de aviso sobre o login
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingSM + 4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.primaryColor.withAlpha(30),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.spacingSM),
                  Expanded(
                    child: Text(
                      'Acesso somente utilizando login via e-mail funcional (Microsoft).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingMD),
            // Botão de Acesso
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.buttonBorderRadius,
                  ),
                ),
              ),
              onPressed: _isCheckingAccess ? null : _checkAccessAndNavigate,
              icon: _isCheckingAccess
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                _isCheckingAccess ? 'Verificando acesso...' : 'ACESSAR SIMULADOR',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(DashboardProvider provider) {
    final perfilIncompleto = provider.userData?.unidadeAtualNome == null;
    return RefreshIndicator(
      onRefresh: () => provider.fetchInitialData(),
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMD,
          vertical: AppConstants.spacingLG,
        ),
        children: [
          if (perfilIncompleto)
            BoasVindasCard(
              onCompletarPerfil: () => Navigator.of(context)
                  .pushNamed(AppRoutes.completarPerfil),
            ),
          if (perfilIncompleto) const SizedBox(height: AppConstants.spacingMD),
          MinhaLotacaoCard(
            userProfile: provider.userData!,
            onEdit: _showEditLotacaoModal,
          ),
          const SizedBox(height: AppConstants.spacingMD),
          MinhasIntencoesCard(
            intencoes: provider.intencoes,
            onEdit: _showEditIntencoesModal,
          ),
          const SizedBox(height: AppConstants.spacingMD),
          _buildMatchesSection(provider),
          const SizedBox(height: AppConstants.spacingMD),
          _buildNovosSoldadosCard(context),
          const SizedBox(height: AppConstants.spacingMD),
          const MapaCard(),
          const SizedBox(height: AppConstants.spacingMD),
          const ChatCard(),
          const SizedBox(height: AppConstants.spacingMD),
          AdminForumButtons(
            isEmbaixador: provider.userData!.isEmbaixador,
          ),
          const SizedBox(height: AppConstants.spacingMD),
          const ParceirosCard(parceiros: []),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(DashboardProvider provider) {
    final perfilIncompleto = provider.userData?.unidadeAtualNome == null;
    return RefreshIndicator(
      onRefresh: () => provider.fetchInitialData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLG),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
            child: Column(
              children: [
                if (perfilIncompleto)
                  BoasVindasCard(
                    onCompletarPerfil: () => Navigator.of(context)
                        .pushNamed(AppRoutes.completarPerfil),
                  ),
                if (perfilIncompleto)
                  const SizedBox(height: AppConstants.spacingMD),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          MinhaLotacaoCard(
                            userProfile: provider.userData!,
                            onEdit: _showEditLotacaoModal,
                          ),
                          const SizedBox(height: AppConstants.spacingMD),
                          MinhasIntencoesCard(
                            intencoes: provider.intencoes,
                            onEdit: _showEditIntencoesModal,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMD),
                    Expanded(
                      child: Column(
                        children: [
                          const ChatCard(),
                          const SizedBox(height: AppConstants.spacingMD),
                          AdminForumButtons(
                            isEmbaixador: provider.userData!.isEmbaixador,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingMD),
                _buildMatchesSection(provider),
                const SizedBox(height: AppConstants.spacingMD),
                _buildNovosSoldadosCard(context),
                const SizedBox(height: AppConstants.spacingMD),
                const MapaCard(),
                const SizedBox(height: AppConstants.spacingMD),
                const ParceirosCard(parceiros: []),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(DashboardProvider provider) {
    final perfilIncompleto = provider.userData?.unidadeAtualNome == null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppConstants.sidebarWidth,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLG,
              vertical: AppConstants.spacingXL,
            ),
            children: [
              MinhaLotacaoCard(
                userProfile: provider.userData!,
                onEdit: _showEditLotacaoModal,
              ),
              const SizedBox(height: AppConstants.spacingMD),
              MinhasIntencoesCard(
                intencoes: provider.intencoes,
                onEdit: _showEditIntencoesModal,
              ),
              const SizedBox(height: AppConstants.spacingMD),
              const ChatCard(),
              const SizedBox(height: AppConstants.spacingMD),
              AdminForumButtons(
                isEmbaixador: provider.userData!.isEmbaixador,
              ),
              const SizedBox(height: AppConstants.spacingMD),
              const ParceirosCard(parceiros: []),
            ],
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.fetchInitialData(),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingLG,
                vertical: AppConstants.spacingXL,
              ),
              children: [
                if (perfilIncompleto)
                  BoasVindasCard(
                    onCompletarPerfil: () => Navigator.of(context)
                        .pushNamed(AppRoutes.completarPerfil),
                  ),
                if (perfilIncompleto)
                  const SizedBox(height: AppConstants.spacingMD),
                _buildMatchesSection(provider),
                const SizedBox(height: AppConstants.spacingMD),
                _buildNovosSoldadosCard(context),
                const SizedBox(height: AppConstants.spacingMD),
                const MapaCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}