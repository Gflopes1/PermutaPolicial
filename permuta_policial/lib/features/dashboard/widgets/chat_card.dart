// /lib/features/dashboard/widgets/chat_card.dart

import 'package:flutter/material.dart';
import '../../chat/screens/chat_list_screen.dart';

class ChatCard extends StatelessWidget {
  const ChatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mensagens', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.chat_bubble_outline, color: Theme.of(context).textTheme.bodySmall?.color),
              title: const Text('Suas conversas recentes aparecerão aqui.'),
              subtitle: const Text('Funcionalidade em desenvolvimento.'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChatListScreen(),
                    ),
                  );
                },
                child: const Text('Ver Todas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}