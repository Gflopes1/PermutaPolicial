// /lib/features/chat/screens/chat_conversa_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class ChatConversaScreen extends StatefulWidget {
  final int conversaId;
  final String outroUsuarioNome;

  const ChatConversaScreen({
    super.key,
    required this.conversaId,
    required this.outroUsuarioNome,
  });

  @override
  State<ChatConversaScreen> createState() => _ChatConversaScreenState();
}

class _ChatConversaScreenState extends State<ChatConversaScreen> {
  final TextEditingController _mensagemController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      provider.loadMensagens(widget.conversaId);
    });
  }

  @override
  void dispose() {
    _mensagemController.dispose();
    _scrollController.dispose();
    final provider = Provider.of<ChatProvider>(context, listen: false);
    provider.leaveConversa();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMensagem() async {
    final mensagem = _mensagemController.text.trim();
    if (mensagem.isEmpty) return;

    final provider = Provider.of<ChatProvider>(context, listen: false);
    
    // Limpa o campo imediatamente para evitar múltiplos envios
    _mensagemController.clear();
    
    final success = await provider.sendMensagem(mensagem);

    if (success) {
      provider.stopTyping();
      _isTyping = false;
      _scrollToBottom();
    } else {
      // Se falhou, restaura a mensagem
      _mensagemController.text = mensagem;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.outroUsuarioNome),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.mensagens.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.mensagens.length,
                  itemBuilder: (context, index) {
                    final mensagem = provider.mensagens[index];
                    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
                    final currentUserId = dashboardProvider.userData?.id;
                    final isMe = mensagem['remetente_id'] == currentUserId;
                    final remetenteNome = mensagem['remetente_nome'] ?? 'Usuário';
                    final remetenteIdentificado = mensagem['remetente_identificado'] ?? 1;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mostra nome do remetente se não for anônimo ou se já foi revelado
                            if (!isMe && remetenteIdentificado == 1)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  remetenteNome,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            Text(
                              mensagem['mensagem'] ?? '',
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(mensagem['criado_em']),
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.black54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (provider.isTyping)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '${provider.typingUser ?? "Alguém"} está digitando...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(20),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mensagemController,
                        decoration: const InputDecoration(
                          hintText: 'Digite uma mensagem...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        maxLines: null,
                        onChanged: (value) {
                          if (!_isTyping && value.isNotEmpty) {
                            _isTyping = true;
                            provider.startTyping();
                          } else if (_isTyping && value.isEmpty) {
                            _isTyping = false;
                            provider.stopTyping();
                          }
                        },
                        onSubmitted: (_) => _sendMensagem(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMensagem,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Ontem';
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return '';
    }
  }
}




