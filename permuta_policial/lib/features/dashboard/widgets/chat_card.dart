// /lib/features/dashboard/widgets/chat_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../chat/providers/chat_provider.dart';
import '../../../core/config/app_theme.dart';

class ChatCard extends StatelessWidget {
  const ChatCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final mensagensNaoLidas = chatProvider.mensagensNaoLidas;
        
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outline.withAlpha(30),
              width: 1,
            ),
          ),
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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryLight, size: 40),
                      ),
                      if (mensagensNaoLidas > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              mensagensNaoLidas > 99 ? '99+' : mensagensNaoLidas.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mensagens',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mensagensNaoLidas > 0
                        ? '$mensagensNaoLidas ${mensagensNaoLidas == 1 ? 'mensagem não lida' : 'mensagens não lidas'}'
                        : 'Suas conversas',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mensagensNaoLidas > 0 ? AppTheme.primaryLight : Colors.grey[600],
                      fontWeight: mensagensNaoLidas > 0 ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                    maxLines: 2,
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
