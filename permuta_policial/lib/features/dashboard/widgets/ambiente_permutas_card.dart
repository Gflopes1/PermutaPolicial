// /lib/features/dashboard/widgets/ambiente_permutas_card.dart

import 'package:flutter/material.dart';
import '../../../core/models/intencao.dart';
import '../../../core/models/match_results.dart';
import '../../../core/config/app_routes.dart';

class AmbientePermutasCard extends StatelessWidget {
  final List<Intencao> intencoes;
  final FullMatchResults? matches;
  final VoidCallback onEditIntencoes;

  const AmbientePermutasCard({
    super.key,
    required this.intencoes,
    this.matches,
    required this.onEditIntencoes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalMatches = (matches?.diretas.length ?? 0) + 
                        (matches?.interessados.length ?? 0) + 
                        (matches?.triangulares.length ?? 0);
    
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(AppRoutes.permutas);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.swap_horiz, color: theme.primaryColor, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                'Ambiente de Permutas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${intencoes.length} intenções • $totalMatches matches',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

