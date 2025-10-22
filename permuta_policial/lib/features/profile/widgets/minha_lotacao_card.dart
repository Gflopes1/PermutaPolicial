// /lib/features/dashboard/widgets/minha_lotacao_card.dart

import 'package:flutter/material.dart';
import '../../../core/models/user_profile.dart'; // Importando o modelo do novo local

class MinhaLotacaoCard extends StatelessWidget {
  final UserProfile userProfile;
  final VoidCallback onEdit;

  const MinhaLotacaoCard({
    super.key,
    required this.userProfile,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLocation = userProfile.unidadeAtualNome != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Minha Lotação Atual', style: theme.textTheme.titleLarge),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.pin_drop_outlined, color: theme.colorScheme.primary),
              title: Text(
                hasLocation ? userProfile.unidadeAtualNome! : 'Não definida',
                style: hasLocation ? null : TextStyle(color: theme.textTheme.bodySmall?.color, fontStyle: FontStyle.italic),
              ),
              subtitle: Text(
                hasLocation ? '${userProfile.municipioAtualNome} - ${userProfile.estadoAtualSigla}' : 'Complete seu perfil para ver os matches',
              ),
            ),
            if (userProfile.postoGraduacaoNome != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                child: Chip(
                  avatar: const Icon(Icons.military_tech_outlined, size: 18),
                  label: Text(userProfile.postoGraduacaoNome!, style: const TextStyle(fontWeight: FontWeight.w500)),
                  backgroundColor: theme.colorScheme.surface,
                  side: BorderSide(color: theme.dividerColor),
                ),
              ),
            if (userProfile.lotacaoInterestadual)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                child: Chip(
                  avatar: Icon(Icons.public, color: Colors.green[200], size: 18),
                  label: const Text('Permuta Interestadual Ativada'),
                   backgroundColor: theme.colorScheme.surface,
                   side: BorderSide(color: theme.dividerColor),
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Editar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}