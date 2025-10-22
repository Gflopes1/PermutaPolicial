// /lib/features/landing/screens/landing_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// MUDANÇA: Importando o arquivo de rotas centralizado
import '../../../core/config/app_routes.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
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

    _animationController.forward();
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 0, 21, 44),
              Color.fromARGB(255, 1, 67, 121),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 80 : (isSmallScreen ? 24 : 32),
                vertical: 32,
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
                        Hero(
                          tag: 'app_logo',
                          child: Image.asset(
                            'assets/images/logo_tatico.png',
                            width: isSmallScreen ? 100 : 140,
                            height: isSmallScreen ? 100 : 140,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 32),

                        // Título principal
                        Text(
                          'Bem-vindo ao\nPermuta Policial',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24 : (isTablet ? 32 : 28),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),

                        // Descrição
                        Text(
                          'A primeira plataforma do Brasil para conectar agentes de segurança e viabilizar permutas de forma inteligente.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 32 : 48),

                        // Cards de benefícios
                        _buildBenefitCard(icon: Icons.people_outline, title: 'Conexões Inteligentes', description: 'Encontre matches diretos e triangulares'),
                        const SizedBox(height: 12),
                        _buildBenefitCard(icon: Icons.security, title: 'Seguro e Verificado', description: 'Apenas agentes verificados têm acesso'),
                        const SizedBox(height: 12),
                        _buildBenefitCard(icon: Icons.map_outlined, title: 'Mapa Nacional', description: 'Visualize oportunidades em todo o Brasil'),
                        SizedBox(height: isSmallScreen ? 32 : 48),

                        // Botão principal
                        ElevatedButton(
                          onPressed: () {
                            // MUDANÇA: Usando a constante de rota
                            Navigator.of(context).pushReplacementNamed(AppRoutes.auth);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Entrar ou Criar Conta', style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 16),

                        // Botão explorar mapa
                        OutlinedButton.icon(
                          onPressed: () {
                            // MUDANÇA: Usando a constante de rota
                            Navigator.of(context).pushNamed(AppRoutes.mapa, arguments: true);
                          },
                          icon: const Icon(Icons.explore_outlined, size: 20),
                          label: Text('Explorar Mapa como Visitante', style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54, width: 1.5),
                            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 32 : 48),

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
      ),
    );
  }

  Widget _buildBenefitCard({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
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
              onPressed: () => _launchURL('https://brasil.permutapolicial.com.br/termos.html'),
              child: Text('Termos de Uso', style: TextStyle(color: Colors.white70, fontSize: isSmall ? 12 : 13)),
            ),
            const Text('|', style: TextStyle(color: Colors.white70)),
            TextButton(
              onPressed: () => _launchURL('https://brasil.permutapolicial.com.br/privacidade.html'),
              child: Text('Política de Privacidade', style: TextStyle(color: Colors.white70, fontSize: isSmall ? 12 : 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('© 2025 Permuta Policial', style: TextStyle(color: Colors.white54, fontSize: isSmall ? 11 : 12)),
      ],
    );
  }
}