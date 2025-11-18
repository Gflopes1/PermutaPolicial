// /lib/features/dashboard/widgets/mapa_card.dart

import 'package:flutter/material.dart';
import '../../../core/config/app_routes.dart';

class MapaCard extends StatelessWidget {
  const MapaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(AppRoutes.mapa);
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
                child: Icon(Icons.explore_outlined, color: theme.primaryColor, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                'Mapa',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Explore permutas',
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