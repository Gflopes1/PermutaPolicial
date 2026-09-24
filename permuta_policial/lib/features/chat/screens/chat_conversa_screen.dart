// /lib/features/chat/screens/chat_conversa_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/api/repositories/chat_repository.dart';
import 'chat_contato_screen.dart';

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
  bool _anonPopupShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user == null) {
        await auth.tryAutoLogin();
      }
      if (!mounted) return;

      final provider = Provider.of<ChatProvider>(context, listen: false);
      await provider.loadMensagens(widget.conversaId);
      if (!mounted) return;
      _scrollToBottom(jump: true);
      _maybeShowAnonimatoPopup(provider);
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

  int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  /// Resolve o ID do usuário logado — inclusive ao abrir o chat via push,
  /// quando Auth/Dashboard ainda não carregaram o perfil.
  int? _currentUserId(BuildContext context, {Map<String, dynamic>? conversa}) {
    final fromAuth = context.read<AuthProvider>().user?.id ??
        context.read<DashboardProvider>().userData?.id;
    if (fromAuth != null && fromAuth > 0) return fromAuth;

    if (conversa != null) {
      final outro = _parseId(conversa['outro_usuario_id']);
      final u1 = _parseId(conversa['usuario1_id']);
      final u2 = _parseId(conversa['usuario2_id']);
      if (outro != null && u1 != null && u2 != null) {
        return outro == u1 ? u2 : u1;
      }
    }
    return null;
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMensagem() async {
    final mensagem = _mensagemController.text.trim();
    if (mensagem.isEmpty) return;

    final provider = Provider.of<ChatProvider>(context, listen: false);
    _mensagemController.clear();

    final success = await provider.sendMensagem(
      mensagem,
      remetenteId: _currentUserId(context, conversa: provider.conversaAtual),
    );

    if (success) {
      provider.stopTyping();
      _isTyping = false;
      _scrollToBottom();
    } else {
      _mensagemController.text = mensagem;
    }
  }

  void _maybeShowAnonimatoPopup(ChatProvider provider) {
    if (_anonPopupShown) return;
    final conversa = provider.conversaAtual;
    if (conversa == null) return;

    final isAnonima = conversa['anonima'] == true || conversa['anonima'] == 1;
    final remetenteRevelado =
        conversa['remetente_revelado'] == true || conversa['remetente_revelado'] == 1;
    final iniciadaPor = conversa['iniciada_por'];
    final currentUserId = _currentUserId(context, conversa: conversa);

    if (!isAnonima || remetenteRevelado || iniciadaPor == currentUserId) return;

    _anonPopupShown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Conversa anônima'),
        content: const Text(
          'Alguém iniciou uma conversa com você. Você pode ver os dados de quem enviou a mensagem. '
          'Seus dados só serão exibidos se você aceitar compartilhar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendi'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await provider.aceitarCompartilharDados(widget.conversaId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dados compartilhados com sucesso'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Aceitar compartilhar'),
          ),
        ],
      ),
    );
  }

  String _displayTitle(Map<String, dynamic>? conversa) {
    if (conversa != null) {
      final nome = conversa['outro_usuario_nome'] as String?;
      if (nome != null && nome.isNotEmpty) return nome;
    }
    return widget.outroUsuarioNome;
  }

  bool _podeVerPerfil(Map<String, dynamic>? conversa) {
    if (conversa == null) return false;
    return conversa['pode_ver_perfil'] == 1 || conversa['pode_ver_perfil'] == true;
  }

  Future<void> _openPerfil() async {
    final repo = context.read<ChatRepository>();
    await ChatContatoScreen.open(context, repo, widget.conversaId);
  }

  Widget _buildAceitarCompartilharBanner(ChatProvider provider, Map<String, dynamic>? conversa) {
    if (conversa == null) return const SizedBox.shrink();

    final isAnonima = conversa['anonima'] == true || conversa['anonima'] == 1;
    final remetenteRevelado =
        conversa['remetente_revelado'] == true || conversa['remetente_revelado'] == 1;
    final iniciadaPor = conversa['iniciada_por'];
    final currentUserId = _currentUserId(context, conversa: conversa);

    if (!isAnonima || remetenteRevelado || iniciadaPor == currentUserId) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Conversa Anônima',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Você pode ver quem iniciou a conversa. Seus dados só serão exibidos após aceitar compartilhar.',
            style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await provider.aceitarCompartilharDados(widget.conversaId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dados compartilhados com sucesso'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Aceitar Compartilhar Meus Dados'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ChatProvider>(
          builder: (context, provider, _) {
            final conversa = provider.conversaAtual;
            final titulo = _displayTitle(conversa);
            final podeVer = _podeVerPerfil(conversa);

            if (!podeVer) {
              return Text(titulo);
            }

            return InkWell(
              onTap: _openPerfil,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(titulo, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.info_outline, size: 18),
                ],
              ),
            );
          },
        ),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, provider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'excluir') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Excluir Conversa'),
                        content: const Text(
                          'Tem certeza que deseja excluir esta conversa? Esta ação não pode ser desfeita.',
                        ),
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
                        await provider.excluirConversa(widget.conversaId);
                        if (mounted) {
                          Navigator.of(context).pop();
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
                              content: Text('Erro ao excluir: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'excluir',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Excluir Conversa'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer2<ChatProvider, AuthProvider>(
        builder: (context, provider, auth, child) {
          if (provider.isLoading && provider.mensagens.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversa = provider.conversaAtual;
          final currentUserId = _currentUserId(context, conversa: conversa);

          if (!provider.isLoading && provider.mensagens.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients &&
                  _scrollController.position.pixels < _scrollController.position.maxScrollExtent - 80) {
                // Mantém scroll no fim após novas mensagens se usuário já estava no fim
              }
            });
          }

          return Column(
            children: [
              _buildAceitarCompartilharBanner(provider, conversa),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: provider.mensagens.length,
                  itemBuilder: (context, index) {
                    final mensagem = provider.mensagens[index];
                    final remetenteIdRaw = mensagem['remetente_id'];
                    final remetenteId = remetenteIdRaw is int
                        ? remetenteIdRaw
                        : int.tryParse(remetenteIdRaw?.toString() ?? '0') ?? 0;
                    final currentUserIdInt = currentUserId ?? 0;
                    final isMe = remetenteId == currentUserIdInt && currentUserIdInt != 0;
                    final remetenteNome = mensagem['remetente_nome'] ?? 'Usuário';
                    final remetenteIdentificado = mensagem['remetente_identificado'] ?? 1;
                    final isPending = mensagem['pending'] == true;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context).primaryColor
                              : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(12),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMe && remetenteIdentificado == 1)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  remetenteNome,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            Text(
                              mensagem['mensagem'] ?? '',
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(mensagem['criado_em']),
                                  style: TextStyle(
                                    color: isMe ? Colors.white70 : Colors.black54,
                                    fontSize: 10,
                                  ),
                                ),
                                if (isPending) ...[
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: isMe ? Colors.white70 : Colors.black45,
                                    ),
                                  ),
                                ],
                              ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${provider.typingUser ?? "Alguém"} está digitando...',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ),
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(25),
                        blurRadius: 4,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _mensagemController,
                          style: const TextStyle(color: Colors.black),
                          cursorColor: Colors.black87,
                          decoration: InputDecoration(
                            hintText: 'Digite uma mensagem...',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
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
                      IconButton.filled(
                        onPressed: _sendMensagem,
                        icon: const Icon(Icons.send, size: 20),
                      ),
                    ],
                  ),
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
        return 'Ontem ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }
}
