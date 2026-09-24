import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_router.dart';
import '../../../core/models/consultoria_advogado.dart';
import 'consultoria_advogado_card.dart';

class ConsultoriaJuridicaSection extends StatelessWidget {
  final List<ConsultoriaAdvogado> advogados;

  const ConsultoriaJuridicaSection({
    super.key,
    required this.advogados,
  });

  @override
  Widget build(BuildContext context) {
    if (advogados.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.gavel, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            Text('Consultoria Jurídica', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Advogados e escritórios parceiros para servidores públicos e permutas.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        ...advogados.map(
          (a) => ConsultoriaAdvogadoCard(
            advogado: a,
            onTap: () => context.push('${AppRoutes.consultoriaJuridica}/${a.id}'),
          ),
        ),
      ],
    );
  }
}
