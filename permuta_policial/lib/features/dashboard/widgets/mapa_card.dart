// /lib/features/dashboard/widgets/mapa_card.dart

import 'package:flutter/material.dart';
import '../../../core/config/app_routes.dart';

class MapaCard extends StatelessWidget {
  const MapaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/mapa_placeholder.png'), 
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black.withAlpha(102),
              child: const Center(
                child: Icon(Icons.explore_outlined, color: Colors.white, size: 60),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mapa de Exploração', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Explore visualmente a demanda por permutas em todo o Brasil. Encontre locais com mais policiais querendo sair ou chegar.'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.mapa);
                    },
                    icon: const Icon(Icons.public),
                    label: const Text('Explorar o Mapa Completo'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}