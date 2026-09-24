// /lib/features/chat/screens/chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../../core/config/app_styles.dart';
import '../../../core/config/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_bar_helper.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      provider.initializeSocket();
      provider.loadConversas();
      provider.loadMensagensNaoLidas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversas'),
        actions: [
          ...AppBarHelper.adicionarBotaoRelatarProblema(context),
          Consumer<ChatProvider>(
            builder: (context, provider, child) {
              if (provider.mensagensNaoLidas > 0) {
                return Badge(
                  label: Text(provider.mensagensNaoLidas.toString()),
                  child: const Icon(Icons.notifications),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.conversas.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                    AppStyles.spacingSmall,
                    Text(provider.errorMessage!, style: AppStyles.bodyMedium, textAlign: TextAlign.center),
                    AppStyles.spacingMedium,
                    ElevatedButton(
                      style: AppStyles.primaryButton,
                      onPressed: () => provider.loadConversas(),
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.conversas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 80, color: AppTheme.textTertiary),
                  AppStyles.spacingSmall,
                  Text(
                    'Nenhuma conversa ainda.',
                    style: AppStyles.titleMedium,
                  ),
                  AppStyles.spacingSmall,
                  Text(
                    'Inicie uma conversa com outro usuário!',
                    style: AppStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadConversas();
              await provider.loadMensagensNaoLidas();
            },
            child: ListView.builder(
              itemCount: provider.conversas.length,
              itemBuilder: (context, index) {
                final conversa = provider.conversas[index];
                final mensagensNaoLidas = conversa['mensagens_nao_lidas'] ?? 0;
                
                return Dismissible(
                  key: Key('conversa_${conversa['id']}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white, size: 28),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Excluir Conversa'),
                        content: const Text('Tem certeza que deseja excluir esta conversa? Esta ação não pode ser desfeita.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Excluir'),
                          ),
                        ],
                      ),
                    ) ?? false;
                  },
                  onDismissed: (direction) async {
                    try {
                      await provider.excluirConversa(conversa['id']);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Conversa excluída com sucesso'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao excluir conversa: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      // Recarrega a lista em caso de erro
                      provider.loadConversas();
                    }
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        (conversa['outro_usuario_nome'] ?? '?')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      conversa['outro_usuario_nome'] ?? 'Usuário',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      conversa['ultima_mensagem'] ?? 'Nenhuma mensagem',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (mensagensNaoLidas > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Badge(
                              label: Text(mensagensNaoLidas.toString()),
                              child: const Icon(Icons.chat, size: 20),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: Colors.grey[600],
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Excluir Conversa'),
                                content: const Text('Tem certeza que deseja excluir esta conversa? Esta ação não pode ser desfeita.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('Excluir'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirm == true && mounted) {
                              try {
                                await provider.excluirConversa(conversa['id']);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Conversa excluída com sucesso'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erro ao excluir conversa: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      context.push('/chat/conversa/${conversa['id']}?nome=${Uri.encodeComponent(conversa['outro_usuario_nome'] ?? 'Usuário')}');
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}




