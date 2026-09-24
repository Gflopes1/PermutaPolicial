// /lib/features/premium/screens/premium_success_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_router.dart';
import '../../../core/services/analytics_service.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class PremiumSuccessScreen extends StatefulWidget {
  const PremiumSuccessScreen({super.key});

  @override
  State<PremiumSuccessScreen> createState() => _PremiumSuccessScreenState();
}

class _PremiumSuccessScreenState extends State<PremiumSuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackPageView();
      _refreshUserData();
      _autoRedirect();
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  Future<void> _trackPageView() async {
    try {
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      await analyticsService.trackPageView('/premium/success');
      await analyticsService.trackEvent('premium_subscription_approved');
    } catch (e) {
      debugPrint('Erro ao rastrear analytics: $e');
    }
  }

  Future<void> _refreshUserData() async {
    try {
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      await dashboardProvider.fetchInitialData();
    } catch (e) {
      debugPrint('Erro ao atualizar dados do usuário: $e');
    }
  }

  void _autoRedirect() {
    // Redireciona para o dashboard após 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go(AppRoutes.dashboard);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.amber.shade700,
              Colors.orange.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone de sucesso animado
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 80,
                        color: Colors.green,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Título
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Bem-vindo ao Premium! 🎉',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mensagem
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Sua assinatura foi ativada com sucesso!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Benefícios destacados
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildBenefitRow(
                            context,
                            '✅ Simulados Avançados (até 120 questões)',
                            Colors.white,
                          ),
                          const SizedBox(height: 12),
                          _buildBenefitRow(
                            context,
                            '✅ Modo prática ilimitado',
                            Colors.white,
                          ),
                          const SizedBox(height: 12),
                          _buildBenefitRow(
                            context,
                            '✅ Sem limites diários',
                            Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Botão de continuar
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go(AppRoutes.dashboard);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.amber.shade800,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Continuar para o Dashboard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Link para ver perfil
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: TextButton(
                      onPressed: () {
                        context.go(AppRoutes.meusDados);
                      },
                      child: Text(
                        'Ver meu perfil Premium',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(BuildContext context, String text, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

