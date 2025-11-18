// /lib/features/dashboard/widgets/chat_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../chat/providers/chat_provider.dart';

class ChatCard extends StatelessWidget {
  const ChatCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final mensagensNaoLidas = chatProvider.mensagensNaoLidas;
        
        return Card(
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ChatListScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withAlpha(10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.chat_bubble_outline, color: theme.primaryColor, size: 24),
                      ),
                      if (mensagensNaoLidas > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              mensagensNaoLidas > 99 ? '99+' : mensagensNaoLidas.toString(),
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
                  const SizedBox(height: 10),
                  Text(
                    'Mensagens',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mensagensNaoLidas > 0
                        ? '$mensagensNaoLidas ${mensagensNaoLidas == 1 ? 'mensagem não lida' : 'mensagens não lidas'}'
                        : 'Suas conversas',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mensagensNaoLidas > 0 ? theme.primaryColor : Colors.grey[600],
                      fontWeight: mensagensNaoLidas > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}