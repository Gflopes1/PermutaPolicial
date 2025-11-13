// /lib/features/chat/screens/chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'chat_conversa_screen.dart';

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage!),
                  ElevatedButton(
                    onPressed: () => provider.loadConversas(),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (provider.conversas.isEmpty) {
            return const Center(
              child: Text('Nenhuma conversa ainda.\nInicie uma conversa com outro usuário!'),
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
                
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      (conversa['outro_usuario_nome'] ?? '?')[0].toUpperCase(),
                    ),
                  ),
                  title: Text(conversa['outro_usuario_nome'] ?? 'Usuário'),
                  subtitle: Text(
                    conversa['ultima_mensagem'] ?? 'Nenhuma mensagem',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: mensagensNaoLidas > 0
                      ? Badge(
                          label: Text(mensagensNaoLidas.toString()),
                          child: const Icon(Icons.chat),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => ChatConversaScreen(
                          conversaId: conversa['id'],
                          outroUsuarioNome: conversa['outro_usuario_nome'] ?? 'Usuário',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}


