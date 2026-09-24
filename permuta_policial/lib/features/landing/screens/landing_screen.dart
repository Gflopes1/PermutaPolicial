// /lib/features/landing/screens/landing_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:go_router/go_router.dart';
import '../../../core/config/app_router.dart';
import '../../../core/config/app_styles.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/visitor_prefs.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Lista de benefícios alinhada ao conteúdo público da plataforma
  // (pm.html / llms-full.txt) — funcionalidades gratuitas em destaque.
  static const List<_Benefit> _benefits = [
    _Benefit(
      icon: Icons.compare_arrows,
      title: 'Matches Inteligentes',
      description: 'Diretos, triangulares e ciclos N-way automaticamente',
    ),
    _Benefit(
      icon: Icons.map_outlined,
      title: 'Mapa Nacional',
      description: 'Demanda por município em todo o Brasil, sem login',
    ),
    _Benefit(
      icon: Icons.verified_user_outlined,
      title: 'Perfis Verificados',
      description: 'Verificação de documento garante acesso só a agentes',
    ),
    _Benefit(
      icon: Icons.forum_outlined,
      title: 'Chat e Fórum',
      description: 'Fale com interessados e troque experiências com colegas',
    ),
    _Benefit(
      icon: Icons.store_outlined,
      title: 'Marketplace',
      description: 'Compre e venda equipamentos entre agentes de segurança',
    ),
    _Benefit(
      icon: Icons.schedule_outlined,
      title: 'Gestor de Horas',
      description: 'Organize escalas e compromissos operacionais',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _animationController.value = 1.0;
      } else {
        _animationController.forward();
      }
      _trackPageView();
    });
  }

  Future<void> _trackPageView() async {
    try {
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      await analyticsService.trackPageView('/landing');
      await analyticsService.trackEvent('landing_page_viewed');
    } catch (e) {
      debugPrint('Erro ao rastrear analytics na landing: $e');
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isTablet = size.width > 600;

    return AppStyles.gradientScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 80 : (isSmallScreen ? 24 : 32),
              vertical: isSmallScreen ? 20 : 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      AppStyles.logo(size: isSmallScreen ? 90 : 120),
                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Título principal
                      Text(
                        'Bem-vindo ao\nPermuta Policial',
                        textAlign: TextAlign.center,
                        style: AppStyles.titleLarge.copyWith(
                          fontSize: isSmallScreen ? 24 : (isTablet ? 32 : 28),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 10 : 14),

                      // Descrição
                      Text(
                        'A primeira plataforma do Brasil para conectar agentes de segurança e viabilizar permutas de forma inteligente.',
                        textAlign: TextAlign.center,
                        style: AppStyles.bodyMedium.copyWith(
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Estatísticas rápidas (alinhadas ao hero do site)
                      _buildStatsRow(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 28),

                      // Grid de benefícios (2 colunas)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: isSmallScreen ? 0.95 : 1.05,
                            children: _benefits
                                .map((b) => _buildBenefitCard(
                                      icon: b.icon,
                                      title: b.title,
                                      description: b.description,
                                    ))
                                .toList(),
                          );
                        },
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Selo de confiança / independência
                      _buildTrustBadge(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Botão principal
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Rastreia evento de clique
                            try {
                              final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
                              await analyticsService.trackEvent('landing_cta_clicked', metadata: {'action': 'entrar_criar_conta'});
                            } catch (e) {
                              debugPrint('Erro ao rastrear evento: $e');
                            }
                            if (mounted) {
                              context.go(AppRoutes.auth);
                            }
                          },
                          style: AppStyles.primaryButton.copyWith(
                            padding: WidgetStateProperty.all(
                              EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 18),
                            ),
                          ),
                          child: Text(
                            'Entrar ou Criar Conta',
                            style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botão explorar mapa
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
                              await analyticsService.trackEvent('landing_visitor_mode_clicked');
                            } catch (e) {
                              debugPrint('Erro ao rastrear evento: $e');
                            }
                            await VisitorPrefs.setVisitorMode(true);
                            if (mounted) {
                              context.go(AppRoutes.mapaVisitante);
                            }
                          },
                          icon: const Icon(Icons.explore_outlined, size: 20),
                          label: Text(
                            'Explorar Mapa como Visitante',
                            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                          ),
                          style: AppStyles.outlinedButton.copyWith(
                            padding: WidgetStateProperty.all(
                              EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Rodapé com links
                      _buildFooter(isSmallScreen),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isSmall) {
    Widget stat(String value, String label) {
      return Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 18 : 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: isSmall ? 11 : 12),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        stat('10+', 'Funcionalidades'),
        Container(width: 1, height: 32, color: Colors.white.withAlpha(51)),
        stat('6', 'Corporações\ncontempladas'),
        Container(width: 1, height: 32, color: Colors.white.withAlpha(51)),
        stat('BR', 'Cobertura\nNacional'),
      ],
    );
  }

  Widget _buildBenefitCard({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(bool isSmall) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Plataforma independente, sem vínculo governamental. Perfis verificados por documento.',
              style: TextStyle(color: Colors.white70, fontSize: isSmall ? 10.5 : 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isSmall) {
    return Column(
      children: [
        Divider(color: Colors.white.withAlpha(51), thickness: 1),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            TextButton(
              onPressed: () => _launchURL('https://br.permutapolicial.com.br/termos.html'),
              child: Text('Termos de Uso', style: TextStyle(color: Colors.white70, fontSize: isSmall ? 12 : 13)),
            ),
            const Text('|', style: TextStyle(color: Colors.white70)),
            TextButton(
              onPressed: () => _launchURL('https://br.permutapolicial.com.br/privacidade.html'),
              child: Text('Política de Privacidade', style: TextStyle(color: Colors.white70, fontSize: isSmall ? 12 : 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '© ${DateTime.now().year} Permuta Policial',
          style: TextStyle(color: Colors.white54, fontSize: isSmall ? 11 : 12),
        ),
      ],
    );
  }
}

class _Benefit {
  final IconData icon;
  final String title;
  final String description;

  const _Benefit({required this.icon, required this.title, required this.description});
}