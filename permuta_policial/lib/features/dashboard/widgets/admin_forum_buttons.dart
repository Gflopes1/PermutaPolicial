// /lib/features/dashboard/widgets/admin_forum_buttons.dart

import 'package:flutter/material.dart';
import '../../../core/config/app_routes.dart';

class AdminForumButtons extends StatelessWidget {
  final bool isEmbaixador;
  const AdminForumButtons({super.key, required this.isEmbaixador});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            if (isEmbaixador)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Painel de Administração'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.admin);
                },
              ),
            if (isEmbaixador) const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.forum_outlined),
              title: Text('Fórum da Comunidade'),
              subtitle: Text('Em breve'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: null, // Desabilitado
            ),
          ],
        ),
      ),
    );
  }
}