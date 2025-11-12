// /lib/features/admin/widgets/estatisticas_tab.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/admin_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_display_widget.dart';

class EstatisticasTab extends StatelessWidget {
  final AdminProvider provider;

  const EstatisticasTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.estatisticas == null) {
      return const LoadingWidget();
    }

    if (provider.errorMessage != null && provider.estatisticas == null) {
      return ErrorDisplayWidget(
        customMessage: provider.errorMessage!,
        customTitle: 'Erro ao carregar estatísticas',
        onRetry: () => provider.loadEstatisticas(),
      );
    }

    final stats = provider.estatisticas;
    if (stats == null) {
      return const Center(child: Text('Nenhuma estatística disponível'));
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadEstatisticas(),
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingMD),
        children: [
          _buildStatCard(
            context,
            'Total de Policiais',
            stats['total_policiais']?.toString() ?? '0',
            Icons.people,
            Colors.blue,
          ),
          const SizedBox(height: AppConstants.spacingMD),
          _buildStatCard(
            context,
            'Total de Unidades',
            stats['total_unidades']?.toString() ?? '0',
            Icons.business,
            Colors.green,
          ),
          const SizedBox(height: AppConstants.spacingMD),
          _buildStatCard(
            context,
            'Total de Intenções',
            stats['total_intencoes']?.toString() ?? '0',
            Icons.favorite,
            Colors.red,
          ),
          const SizedBox(height: AppConstants.spacingMD),
          _buildStatCard(
            context,
            'Verificações Pendentes',
            stats['verificacoes_pendentes']?.toString() ?? '0',
            Icons.pending_actions,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLG),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingMD),
              decoration: BoxDecoration(
                color: color.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: AppConstants.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

