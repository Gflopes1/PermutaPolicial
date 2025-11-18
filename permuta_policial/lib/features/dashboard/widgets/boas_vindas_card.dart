// /lib/features/dashboard/widgets/boas_vindas_card.dart

import 'package:flutter/material.dart';

class BoasVindasCard extends StatelessWidget {
  final String nome;
  final bool perfilIncompleto;
  final VoidCallback? onCompletarPerfil;

  const BoasVindasCard({
    super.key,
    required this.nome,
    this.perfilIncompleto = false,
    this.onCompletarPerfil,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, $nome',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Bem-vindo de volta',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (perfilIncompleto) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Complete seu perfil para publicar',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    if (onCompletarPerfil != null)
                      TextButton(
                        onPressed: onCompletarPerfil,
                        child: const Text('Completar Perfil'),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}