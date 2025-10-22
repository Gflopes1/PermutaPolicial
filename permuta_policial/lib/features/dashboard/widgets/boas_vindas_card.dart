// /lib/features/dashboard/widgets/boas_vindas_card.dart

import 'package:flutter/material.dart';

class BoasVindasCard extends StatelessWidget {
  final VoidCallback onCompletarPerfil;

  const BoasVindasCard({super.key, required this.onCompletarPerfil});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(26),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.stars_outlined, color: Colors.yellow, size: 40),
            const SizedBox(height: 12),
            Text(
              'Bem-vindo ao Permuta Policial!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Para começar a ver suas combinações, o primeiro passo é definir sua lotação atual.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onCompletarPerfil,
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: const Text('Completar Perfil Agora'),
            ),
          ],
        ),
      ),
    );
  }
}