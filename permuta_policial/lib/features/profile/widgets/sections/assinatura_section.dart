import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/repositories/payments_repository.dart';
import '../../../../core/config/app_styles.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../shared/widgets/premium_modal.dart';
import '../../../dashboard/providers/dashboard_provider.dart';
import '../section_card.dart';

class AssinaturaSection extends StatelessWidget {
  final UserProfile userProfile;

  const AssinaturaSection({super.key, required this.userProfile});

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';

    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is int) {
        date = DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else {
        return dateValue.toString();
      }

      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateValue.toString();
    }
  }

  Future<void> _cancelarPremium(BuildContext context) async {
    final subscription = userProfile.subscription;
    if (subscription == null || subscription['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar('Não foi possível encontrar a assinatura.'),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Assinatura Premium'),
        content: const Text(
          'Tem certeza que deseja cancelar sua assinatura Premium? '
          'Você perderá acesso aos recursos Premium após o período pago.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Não')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cancelando assinatura...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final paymentsRepo = Provider.of<PaymentsRepository>(context, listen: false);
      final rawId = subscription['id'];
      final subscriptionId = rawId is int ? rawId : int.parse(rawId.toString());

      await paymentsRepo.cancelSubscription(subscriptionId);

      if (!context.mounted) return;
      Navigator.of(context).pop();

      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      await dashboardProvider.fetchInitialData();

      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.successSnackBar('Assinatura cancelada com sucesso!'),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();

      var message = 'Erro ao cancelar assinatura.';
      if (e is ApiException) message = e.userMessage;

      ScaffoldMessenger.of(context).showSnackBar(AppStyles.errorSnackBar(message));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium = userProfile.isPremium;
    final subscription = userProfile.subscription;

    return ProfileSectionCard(
      label: 'Assinatura',
      children: [
        Row(
          children: [
            Icon(
              Icons.workspace_premium,
              color: isPremium ? Colors.amber.shade400 : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Status Premium',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isPremium && subscription != null) ...[
          Text(
            'Você é um membro Premium',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.amber.shade400,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subscription['end_at'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Válido até: ${_formatDate(subscription['end_at'])}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _cancelarPremium(context),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar Premium'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ] else ...[
          Text('Você não possui assinatura Premium', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(context: context, builder: (ctx) => const PremiumModal());
              },
              icon: const Icon(Icons.workspace_premium),
              label: const Text('Assinar Premium'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
