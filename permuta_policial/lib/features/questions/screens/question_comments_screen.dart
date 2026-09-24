import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/questions_provider.dart';
import '../../../core/models/comment.dart';

class QuestionCommentsScreen extends StatefulWidget {
  final int questionId;

  const QuestionCommentsScreen({super.key, required this.questionId});

  @override
  State<QuestionCommentsScreen> createState() => _QuestionCommentsScreenState();
}

class _QuestionCommentsScreenState extends State<QuestionCommentsScreen> {
  List<Comment> _comments = [];
  bool _isLoading = true;
  final Map<int, List<Comment>> _repliesMap = {};
  final Set<int> _expandedComments = {};
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  final Map<int, TextEditingController> _replyControllers = {};
  int? _replyingToCommentId;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    final provider = context.read<QuestionsProvider>();
    final comments = await provider.getComments(widget.questionId, perPage: 50);
    
    setState(() {
      _comments = comments;
      // Inicializa as respostas que já vêm do backend
      for (final comment in comments) {
        if (comment.replies != null && comment.replies!.isNotEmpty) {
          _repliesMap[comment.id!] = comment.replies!;
        }
      }
      _isLoading = false;
    });
  }

  Future<void> _toggleReplies(int commentId) async {
    if (_expandedComments.contains(commentId)) {
      // Ocultar respostas
      setState(() {
        _expandedComments.remove(commentId);
      });
    } else {
      // Mostrar respostas
      if (!_repliesMap.containsKey(commentId)) {
        // Carregar respostas se ainda não foram carregadas
        final provider = context.read<QuestionsProvider>();
        final replies = await provider.getReplies(commentId);
        setState(() {
          _repliesMap[commentId] = replies;
          _expandedComments.add(commentId);
        });
      } else {
        setState(() {
          _expandedComments.add(commentId);
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final provider = context.read<QuestionsProvider>();
    final comment = await provider.createComment(widget.questionId, content);

    if (comment != null && mounted) {
      _commentController.clear();
      _loadComments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentário adicionado com sucesso!')),
      );
    }
  }

  Future<void> _submitReply(int parentCommentId) async {
    final controller = _replyControllers[parentCommentId] ?? _replyController;
    final content = controller.text.trim();
    if (content.isEmpty) return;

    final provider = context.read<QuestionsProvider>();
    final reply = await provider.createComment(
      widget.questionId,
      content,
      parentId: parentCommentId,
    );

    if (reply != null && mounted) {
      controller.clear();
      setState(() {
        _replyingToCommentId = null;
      });
      _loadComments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resposta adicionada com sucesso!')),
      );
    }
  }

  void _startReply(int commentId) {
    if (!_replyControllers.containsKey(commentId)) {
      _replyControllers[commentId] = TextEditingController();
    }
    setState(() {
      _replyingToCommentId = commentId;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comentários'),
      ),
      body: Column(
        children: [
          // Campo para adicionar novo comentário
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Adicione um comentário...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _submitComment,
                    child: const Text('Comentar'),
                  ),
                ),
              ],
            ),
          ),
          // Lista de comentários
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(
                        child: Text('Nenhum comentário ainda. Seja o primeiro!'),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadComments,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            return _buildComment(_comments[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment(Comment comment) {
    final isExpanded = _expandedComments.contains(comment.id);
    final replies = _repliesMap[comment.id] ?? [];
    final hasReplies = comment.repliesCount > 0;
    final isReplying = _replyingToCommentId == comment.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text(
                comment.userNome?.substring(0, 1).toUpperCase() ?? '?',
              ),
            ),
            title: Text(comment.userNome ?? 'Usuário'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(comment.content),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.thumb_up, size: 18),
                      onPressed: () async {
                        await context
                            .read<QuestionsProvider>()
                            .toggleLike(comment.id!);
                        _loadComments();
                      },
                    ),
                    Text('${comment.likesCount}'),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () => _startReply(comment.id!),
                      icon: const Icon(Icons.reply, size: 18),
                      label: const Text('Responder'),
                    ),
                    if (hasReplies)
                      TextButton.icon(
                        onPressed: () => _toggleReplies(comment.id!),
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                        ),
                        label: Text(
                          isExpanded
                              ? 'Ocultar ${comment.repliesCount} resposta${comment.repliesCount > 1 ? 's' : ''}'
                              : 'Ver ${comment.repliesCount} resposta${comment.repliesCount > 1 ? 's' : ''}',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Campo de resposta
          if (isReplying)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _replyControllers[comment.id!] ?? _replyController,
                    decoration: InputDecoration(
                      hintText: 'Escreva sua resposta...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _cancelReply,
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _submitReply(comment.id!),
                        child: const Text('Responder'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // Respostas
          if (isExpanded && replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  ...replies.map((reply) => _buildReply(reply)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReply(Comment reply) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16),
      child: Card(
        color: Colors.grey.shade100,
        child: ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 14,
            child: Text(
              reply.userNome?.substring(0, 1).toUpperCase() ?? '?',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          title: Text(
            reply.userNome ?? 'Usuário',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reply.content,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.thumb_up, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      await context
                          .read<QuestionsProvider>()
                          .toggleLike(reply.id!);
                      _loadComments();
                    },
                  ),
                  Text(
                    '${reply.likesCount}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

