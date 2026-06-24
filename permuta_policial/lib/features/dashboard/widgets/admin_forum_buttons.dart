// /lib/features/dashboard/widgets/admin_forum_buttons.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../forum/screens/forum_list_screen.dart';
import '../../marketplace/providers/marketplace_provider.dart';

class AdminForumButtons extends StatelessWidget {
  final bool isEmbaixador;
  final bool isModerator;
  const AdminForumButtons({
    super.key,
    required this.isEmbaixador,
    this.isModerator = false,
  });

  bool get _hasAdminAccess => isEmbaixador || isModerator;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            if (_hasAdminAccess)
              Consumer<MarketplaceProvider>(
                builder: (context, marketplaceProvider, child) {
                  final pendentesCount = marketplaceProvider.pendentesCount;
                  return ListTile(
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.admin_panel_settings_outlined),
                        if (pendentesCount > 0)
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                pendentesCount > 99 ? '99+' : pendentesCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: const Text('Painel de Administração'),
                    subtitle: pendentesCount > 0
                        ? Text(
                            '$pendentesCount anúncio${pendentesCount > 1 ? 's' : ''} pendente${pendentesCount > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          )
                        : null,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      try {
                        context.push('/admin');
                      } catch (e) {
                        debugPrint('Erro ao navegar para painel de administração: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Erro ao abrir painel de administração. Tente novamente.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            if (_hasAdminAccess) const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.forum_outlined),
              title: const Text('Fórum da Comunidade'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ForumListScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}