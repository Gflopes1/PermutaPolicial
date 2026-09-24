// /lib/shared/widgets/premium_modal.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../features/dashboard/providers/dashboard_provider.dart';

class PremiumModal extends StatelessWidget {
  final VoidCallback? onClose;

  const PremiumModal({super.key, this.onClose});

  Future<void> _assinarAgora(BuildContext context) async {
    // Obtém o usuário logado através do DashboardProvider
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final user = dashboardProvider.userData;
    
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: Usuário não encontrado. Por favor, faça login novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Constrói a URL do Mercado Pago com external_reference
    const baseUrl = 'https://www.mercadopago.com.br/subscriptions/checkout?preapproval_plan_id=a275d465855f42fea607d28c297d0a9c';
    final mercadopagoUrl = '$baseUrl&external_reference=${user.id}';
    
    final uri = Uri.parse(mercadopagoUrl);
    
    try {
      // Removido canLaunchUrl pois pode falhar falsamente no Android 11+
      // Tenta abrir diretamente e trata o erro se falhar
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      if (!launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir o link de pagamento.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Fecha o modal após abrir o link
    if (context.mounted && onClose != null) {
      onClose!();
    }
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.shade700,
              Colors.orange.shade600,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ícone de Coroa
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Título
            Text(
              'Seja Premium por apenas R\$ 11,90',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              '/mês',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Benefícios
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBeneficio(
                    context,
                    '✅ Simulados Avançados (até 120 questões)',
                    Colors.white,
                  ),
                  const SizedBox(height: 12),
                  _buildBeneficio(
                    context,
                    '✅ Modo prática ilimitado',
                    Colors.white,
                  ),
                  const SizedBox(height: 12),
                  _buildBeneficio(
                    context,
                    '✅ Sem limites diários',
                    Colors.white,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botão de Assinar
            ElevatedButton(
              onPressed: () => _assinarAgora(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.amber.shade800,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Assinar Agora',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Botão de Fechar
            TextButton(
              onPressed: () {
                if (onClose != null) {
                  onClose!();
                }
                Navigator.of(context).pop();
              },
              child: Text(
                'Talvez depois',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeneficio(BuildContext context, String texto, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            texto,
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

