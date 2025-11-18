// /lib/features/dashboard/screens/dashboard_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/chat_card.dart';
import '../widgets/admin_forum_buttons.dart';
import '../widgets/parceiros_card.dart';
import '../widgets/mapa_card.dart';
import '../widgets/marketplace_card.dart';
import '../widgets/ambiente_permutas_card.dart';
import '../../../core/models/parceiro.dart';
import '../../notificacoes/providers/notificacoes_provider.dart';
import '../../chat/providers/chat_provider.dart';
import '../../marketplace/screens/marketplace_photo_picker_screen.dart';

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
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchInitialData();
      // Carrega notificações e atualiza contador
      final notifProvider = Provider.of<NotificacoesProvider>(context, listen: false);
      notifProvider.loadNotificacoes();
      // Carrega mensagens não lidas do chat
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.loadMensagensNaoLidas();
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
        message = 'Você não tem permissão para acessar esta funcionalidade. ';
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final now = DateTime.now();
        final shouldExit = _lastBackPressTime != null &&
            now.difference(_lastBackPressTime!) < const Duration(seconds: 2);
        
        if (shouldExit) {
          // Permite sair do app
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          // Mostra mensagem e registra o tempo
          _lastBackPressTime = now;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pressione voltar novamente para sair'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Consumer2<DashboardProvider, NotificacoesProvider>(
        builder: (context, provider, notificacoesProvider, child) {
          return Scaffold(
            appBar: _buildAppBar(context, provider, notificacoesProvider),
            body: _buildBody(context, provider),
            floatingActionButton: _buildFloatingActionButton(context, provider),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    DashboardProvider provider,
    NotificacoesProvider notificacoesProvider,
  ) {
    final theme = Theme.of(context);
    
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Logo pequeno
          Image.asset(
            'images/ic_launcher.png',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.shield, color: theme.primaryColor, size: 24);
            },
          ),
          const SizedBox(width: 8),
          // Título
          Expanded(
            child: Text(
              'Permuta Policial',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Ícone de Perfil
        IconButton(
          icon: Icon(Icons.person_outline, color: theme.iconTheme.color),
          tooltip: 'Meus Dados',
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.meusDados);
          },
        ),
        // Ícone de Notificações com badge
        Consumer<NotificacoesProvider>(
          builder: (context, notifProvider, child) {
            return Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: theme.iconTheme.color),
                  tooltip: 'Notificações',
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.notificacoes);
                  },
                ),
                if (notifProvider.countNaoLidas > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        notifProvider.countNaoLidas > 9 ? '9+' : '${notifProvider.countNaoLidas}',
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
            );
          },
        ),
        // Botão de Ajuda
        IconButton(
          icon: Icon(Icons.help_outline, color: theme.iconTheme.color),
          tooltip: 'Ajuda',
          onPressed: () => _launchURL('https://br.permutapolicial.com.br/help.html'),
        ),
        // Botão de Logout
        IconButton(
          icon: Icon(Icons.logout, color: theme.iconTheme.color),
          tooltip: 'Sair',
          onPressed: _logout,
        ),
      ],
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
    final nome = provider.userData?.nome ?? 'Usuário';
    
    return RefreshIndicator(
      onRefresh: () async {
        await provider.fetchInitialData();
        // Atualiza contador de notificações
        Provider.of<NotificacoesProvider>(context, listen: false).refreshCount();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          // Hero / Boas-Vindas (sempre visível)
          BoasVindasCard(
            nome: nome,
            perfilIncompleto: perfilIncompleto,
            onCompletarPerfil: perfilIncompleto 
              ? () => Navigator.of(context).pushNamed(AppRoutes.completarPerfil)
              : null,
          ),
          const SizedBox(height: 24),
          
          // Grid de Cards Prioritários (2 colunas)
          _buildGridCards(provider),
          const SizedBox(height: 24),
          
          // Card Parceiros (carrossel) - sempre exibe
          ParceirosCard(parceiros: provider.parceiros.map((p) => Parceiro.fromJson(p)).toList()),
          const SizedBox(height: 24),
          
          // Cards "Novos Soldados - e Editais" e Fórum
          _buildNovosSoldadosCard(context),
          const SizedBox(height: 16),
          
          if (provider.userData != null)
            AdminForumButtons(isEmbaixador: provider.userData!.isEmbaixador),
          if (provider.userData != null) const SizedBox(height: 16),
          
        ],
      ),
    );
  }

  Widget _buildGridCards(DashboardProvider provider) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        AmbientePermutasCard(
          intencoes: provider.intencoes,
          matches: provider.matches,
          onEditIntencoes: _showEditIntencoesModal,
        ),
        const ChatCard(),
        const MapaCard(),
        const MarketplaceCard(),
      ],
    );
  }

  // Widget compacto para Minha Lotação

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
            
              AmbientePermutasCard(
                intencoes: provider.intencoes,
                matches: provider.matches,
                onEditIntencoes: _showEditIntencoesModal,
              ),
              const SizedBox(height: 20),
            
              const MarketplaceCard(),
              const SizedBox(height: 20),
              const ChatCard(), 
              const SizedBox(height: 20),
            
              if (provider.userData != null)
                AdminForumButtons(isEmbaixador: provider.userData!.isEmbaixador),
              if (provider.userData != null) const SizedBox(height: 20),
            
              ParceirosCard(parceiros: provider.parceiros.map((p) => Parceiro.fromJson(p)).toList()),
              const SizedBox(height: 20),
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
                    nome: provider.userData?.nome ?? 'Usuário',
                    perfilIncompleto: true,
                    onCompletarPerfil: () => Navigator.of(context).pushNamed(AppRoutes.completarPerfil),
                  ),
                if (perfilIncompleto) const SizedBox(height: 20),
              
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

  Widget _buildFloatingActionButton(BuildContext context, DashboardProvider provider) {
    return FloatingActionButton(
      onPressed: () => _showActionMenu(context, provider),
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.add),
    );
  }

  void _showActionMenu(BuildContext context, DashboardProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildActionMenuItem(
              context,
              icon: Icons.share,
              title: 'Compartilhe nosso aplicativo com um colega',
              onTap: () {
                Navigator.pop(ctx);
                _copiarTexto(
                  context,
                  'Conheça o projeto criado para facilitar permutas e negociações entre agentes de segurança pública https://permutapolicial.com.br',
                );
              },
            ),
            const Divider(height: 32),
            _buildActionMenuItem(
              context,
              icon: Icons.account_balance_wallet,
              title: 'Apoie o projeto - PIX',
              onTap: () {
                Navigator.pop(ctx);
                _copiarChavePix(context);
              },
            ),
            const Divider(height: 32),
            _buildActionMenuItem(
              context,
              icon: Icons.add_photo_alternate,
              title: 'Criar anúncio',
              onTap: () {
                Navigator.pop(ctx);
                _navegarParaCriarAnuncio(context, provider);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _copiarTexto(BuildContext context, String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Texto copiado para a área de transferência!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copiarChavePix(BuildContext context) {
    const chavePix = '0938edff-bb0b-4a97-b8c5-3591cbf4d621';
    Clipboard.setData(const ClipboardData(text: chavePix));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chave PIX copiada com sucesso, obrigado pelo apoio!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navegarParaCriarAnuncio(BuildContext context, DashboardProvider provider) async {
    final user = provider.userData;
    
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
    
    if (result == true && mounted) {
      // Recarrega dados se necessário
      provider.fetchInitialData();
    }
  }
}