// /lib/features/forum/screens/forum_topico_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/forum_provider.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';

class ForumTopicoScreen extends StatefulWidget {
  final int topicoId;

  const ForumTopicoScreen({super.key, required this.topicoId});

  @override
  State<ForumTopicoScreen> createState() => _ForumTopicoScreenState();
}

class _ForumTopicoScreenState extends State<ForumTopicoScreen> {
  final TextEditingController _respostaController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ForumProvider>(context, listen: false);
      provider.loadTopico(widget.topicoId);
    });
  }

  @override
  void dispose() {
    _respostaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _enviarResposta() async {
    final conteudo = _respostaController.text.trim();
    if (conteudo.isEmpty) return;

    final provider = Provider.of<ForumProvider>(context, listen: false);
    final success = await provider.createResposta(widget.topicoId, conteudo);

    if (success && mounted) {
      _respostaController.clear();
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tópico'),
        actions: [
          Consumer<DashboardProvider>(
            builder: (context, dashboardProvider, child) {
              final isAdmin = dashboardProvider.userData?.isEmbaixador ?? false;
              if (!isAdmin) return const SizedBox.shrink();
              
              return Consumer<ForumProvider>(
                builder: (context, provider, child) {
                  final topico = provider.topicoAtual;
                  if (topico == null) return const SizedBox.shrink();
                  
                  return PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      final topicoId = topico['id'];
                      switch (value) {
                        case 'fixar':
                          await provider.toggleFixarTopico(topicoId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  topico['fixado'] == true
                                      ? 'Tópico desfixado'
                                      : 'Tópico fixado',
                                ),
                              ),
                            );
                          }
                          break;
                        case 'bloquear':
                          await provider.toggleBloquearTopico(topicoId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  topico['bloqueado'] == true
                                      ? 'Tópico desbloqueado'
                                      : 'Tópico bloqueado',
                                ),
                              ),
                            );
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'fixar',
                        child: Row(
                          children: [
                            Icon(
                              topico['fixado'] == true
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              topico['fixado'] == true
                                  ? 'Desfixar Tópico'
                                  : 'Fixar Tópico',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'bloquear',
                        child: Row(
                          children: [
                            Icon(
                              topico['bloqueado'] == true
                                  ? Icons.lock_open
                                  : Icons.lock,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              topico['bloqueado'] == true
                                  ? 'Desbloquear Tópico'
                                  : 'Bloquear Tópico',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<ForumProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.topicoAtual == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.topicoAtual == null) {
            return const Center(child: Text('Tópico não encontrado'));
          }

          final topico = provider.topicoAtual!;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho do tópico
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (topico['fixado'] == true)
                                    const Icon(Icons.push_pin, color: Colors.orange, size: 20),
                                  Expanded(
                                    child: Text(
                                      topico['titulo'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                topico['conteudo'] ?? '',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  CircleAvatar(
                                    child: Text(
                                      (topico['autor_nome'] ?? '?')[0].toUpperCase(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        topico['autor_nome'] ?? 'Autor desconhecido',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        _formatDate(topico['criado_em']),
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.thumb_up_outlined),
                                    onPressed: () {
                                      provider.toggleReacao(
                                        tipo: 'curtida',
                                        topicoId: topico['id'],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Respostas',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // Lista de respostas
                      if (provider.respostas.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('Nenhuma resposta ainda.\nSeja o primeiro a responder!'),
                          ),
                        )
                      else
                        ...provider.respostas.map((resposta) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        child: Text(
                                          (resposta['autor_nome'] ?? '?')[0].toUpperCase(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              resposta['autor_nome'] ?? 'Autor desconhecido',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              _formatDate(resposta['criado_em']),
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.thumb_up_outlined),
                                        onPressed: () {
                                          provider.toggleReacao(
                                            tipo: 'curtida',
                                            respostaId: resposta['id'],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(resposta['conteudo'] ?? ''),
                                  if (resposta['comentarios'] != null && (resposta['comentarios'] as List).isNotEmpty)
                                    ...(resposta['comentarios'] as List).map((comentario) {
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 16, top: 8),
                                        child: Card(
                                          color: Colors.grey[100],
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  comentario['autor_nome'] ?? 'Autor',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  comentario['conteudo'] ?? '',
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
              // Campo de resposta
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
                        controller: _respostaController,
                        decoration: const InputDecoration(
                          hintText: 'Escreva uma resposta...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        maxLines: null,
                        onSubmitted: (_) => _enviarResposta(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _enviarResposta,
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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp.toString());
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}

