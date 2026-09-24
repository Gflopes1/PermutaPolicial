import 'package:flutter/material.dart';

class ReferralProgressBar extends StatelessWidget {
  final int verifiedCount;
  final int? nextLevel;
  final int remaining;
  final double progress;
  final String tierLabel;

  const ReferralProgressBar({
    super.key,
    required this.verifiedCount,
    this.nextLevel,
    required this.remaining,
    required this.progress,
    required this.tierLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Indicados verificados: $verifiedCount', style: theme.textTheme.bodyMedium),
            Chip(
              label: Text(tierLabel, style: const TextStyle(fontSize: 11)),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        if (nextLevel != null) ...[
          const SizedBox(height: 8),
          Text(
            remaining > 0
                ? 'Faltam $remaining para o próximo nível ($nextLevel)'
                : 'Você atingiu o nível máximo!',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
            ),
          ),
        ],
      ],
    );
  }
}
