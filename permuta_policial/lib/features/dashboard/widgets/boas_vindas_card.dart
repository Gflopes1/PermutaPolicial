// /lib/features/dashboard/widgets/boas_vindas_card.dart

import 'package:flutter/material.dart';

class BoasVindasCard extends StatelessWidget {
  final String nome;
  final bool perfilIncompleto;
  final VoidCallback? onCompletarPerfil;
  final bool compact;

  const BoasVindasCard({
    super.key,
    required this.nome,
    this.perfilIncompleto = false,
    this.onCompletarPerfil,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = compact ? 16.0 : 24.0;
    
    return Card(
      color: theme.cardColor,
      margin: compact ? EdgeInsets.zero : null,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Text(
              'Olá, $nome',
              style: (compact ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: compact ? 4 : 8),
            Text(
              'Bem-vindo de volta',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontSize: compact ? 13 : null,
              ),
            ),
            if (perfilIncompleto) ...[
              SizedBox(height: compact ? 10 : 16),
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