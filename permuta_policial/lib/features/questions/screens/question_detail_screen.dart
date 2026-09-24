import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/questions_provider.dart';
import '../../../core/models/question.dart';
import '../../../core/models/comment.dart';
import 'package:go_router/go_router.dart';

class QuestionDetailScreen extends StatefulWidget {
  final int questionId;

  const QuestionDetailScreen({super.key, required this.questionId});

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  Question? _question;
  List<Comment> _comments = [];
  bool _isLoading = true;
  final Map<int, List<Comment>> _repliesMap = {};
  final Set<int> _expandedComments = {};

  @override
  void initState() {
    super.initState();
    _loadQuestion();
    _loadComments();
  }

  Future<void> _loadQuestion() async {
    final provider = context.read<QuestionsProvider>();
    final question = await provider.getQuestionById(widget.questionId);
    setState(() {
      _question = question;
      _isLoading = false;
    });
  }

  Future<void> _loadComments() async {
    final provider = context.read<QuestionsProvider>();
    final comments = await provider.getComments(widget.questionId);
    setState(() {
      _comments = comments;
      // Inicializa as respostas que já vêm do backend
      for (final comment in comments) {
        if (comment.replies != null && comment.replies!.isNotEmpty) {
          _repliesMap[comment.id!] = comment.replies!;
        }
      }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_question == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Questão')),
        body: const Center(child: Text('Questão não encontrada')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Questão'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _question!.pergunta,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              '${_question!.assunto}${_question!.subassunto != null ? ' • ${_question!.subassunto}' : ''}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ..._question!.alternativas.asMap().entries.map((entry) {
              final index = entry.key;
              final alternativa = entry.value;
              final letter = String.fromCharCode(97 + index);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text(letter.toUpperCase())),
                  title: Text(alternativa),
                ),
              );
            }),
            if (_question!.explicacao != null) ...[
              const SizedBox(height: 24),
              Card(
                color: const Color.fromARGB(255, 0, 0, 0),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explicação',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(_question!.explicacao!),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Comentários (${_comments.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_comments.isEmpty)
              const Text('Nenhum comentário ainda.')
            else
              ..._comments.take(3).map((comment) => _buildComment(comment)),
            if (_comments.length > 3)
              TextButton(
                onPressed: () {
                  context.push('/questions/comments/${widget.questionId}');
                },
                child: const Text('Ver todos os comentários'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComment(Comment comment) {
    final isExpanded = _expandedComments.contains(comment.id);
    final replies = _repliesMap[comment.id] ?? [];
    final hasReplies = comment.repliesCount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text(comment.userNome?.substring(0, 1).toUpperCase() ?? '?'),
            ),
            title: Text(comment.userNome ?? 'Usuário'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.content),
                const SizedBox(height: 4),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.thumb_up, size: 18),
                      onPressed: () async {
                        await context.read<QuestionsProvider>().toggleLike(comment.id!);
                        // Recarregar comentários para atualizar likes
                        _loadComments();
                      },
                    ),
                    Text('${comment.likesCount}'),
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
          if (isExpanded && replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
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
                      await context.read<QuestionsProvider>().toggleLike(reply.id!);
                      // Recarregar comentários para atualizar likes
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


