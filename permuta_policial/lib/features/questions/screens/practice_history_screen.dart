import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/questions_provider.dart';

class PracticeHistoryScreen extends StatefulWidget {
  const PracticeHistoryScreen({super.key});

  @override
  State<PracticeHistoryScreen> createState() => _PracticeHistoryScreenState();
}

class _PracticeHistoryScreenState extends State<PracticeHistoryScreen> {
  List<dynamic> _history = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _total = 0;
  String? _selectedAssunto;

  final List<String> _assuntos = [
    'Direitos',
    'Português',
    'CTB',
    'Informática',
    'Raciocínio Lógico',
    'Contabilidade Geral',
    'Estatística',
    'Física',
    'Inglês',
    'Espanhol'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _loadHistory();
      } catch (e, stackTrace) {
        debugPrint('❌ Erro ao carregar histórico no initState: $e');
        debugPrint('   Stack trace: $stackTrace');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao inicializar histórico: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  Future<void> _loadHistory({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _history = [];
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<QuestionsProvider>();
      final result = await provider.getPracticeHistory(
        page: _currentPage,
        perPage: 5, // Carrega 5 por vez
        assunto: _selectedAssunto,
      );

      if (!mounted) return;

      if (result != null) {
        try {
          setState(() {
            // Verifica se result tem estrutura de paginação
            final resultMap = result as dynamic;
            
            if (resultMap is Map<String, dynamic>) {
              // Verifica se tem 'data' e estrutura de paginação
              if (resultMap.containsKey('data')) {
                final dataValue = resultMap['data'];
                
                // Verifica se data é uma lista
                if (dataValue is List) {
                  final data = List<dynamic>.from(dataValue);
                  final totalValue = resultMap['total'];
                  final total = totalValue is int 
                      ? totalValue 
                      : (totalValue is num 
                          ? totalValue.toInt() 
                          : 0);
                  
                  if (refresh) {
                    _history = data;
                  } else {
                    _history.addAll(data);
                  }
                  _total = total;
                  
                  // Incrementa página se houver mais itens
                  if (_history.length < _total) {
                    _currentPage++;
                  }
                } else {
                  debugPrint('⚠️ Campo "data" não é uma lista: ${dataValue.runtimeType}');
                  _history = [];
                  _total = 0;
                }
              } else {
                debugPrint('⚠️ Resposta não contém campo "data": ${resultMap.keys}');
                _history = [];
                _total = 0;
              }
            } else if (resultMap is List) {
              // Se result é um array direto (compatibilidade)
              final resultList = List<dynamic>.from(resultMap);
              if (refresh) {
                _history = resultList;
              } else {
                _history.addAll(resultList);
              }
              _total = _history.length;
            } else {
              // Estrutura inesperada
              debugPrint('⚠️ Estrutura de resposta inesperada: ${resultMap.runtimeType}');
              debugPrint('   Valor: $resultMap');
              _history = [];
              _total = 0;
            }
            _isLoading = false;
          });
        } catch (e, stackTrace) {
          debugPrint('❌ Erro ao processar histórico: $e');
          debugPrint('   Stack trace: $stackTrace');
          debugPrint('   Result type: ${result.runtimeType}');
          debugPrint('   Result value: $result');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _history = [];
              _total = 0;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao carregar histórico: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Se result é null, houve erro mas foi tratado no provider
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _resetQuestion(int questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetar Questão'),
        content: const Text('Deseja resetar esta questão para poder respondê-la novamente?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Resetar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final provider = context.read<QuestionsProvider>();
        final success = await provider.resetPracticeAnswer(questionId);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Questão resetada com sucesso')),
          );
          _loadHistory(refresh: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              try {
                setState(() {
                  _selectedAssunto = value == 'all' ? null : value;
                });
                _loadHistory(refresh: true);
              } catch (e) {
                debugPrint('❌ Erro ao filtrar histórico: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao filtrar: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Todas')),
              ..._assuntos.map((a) => PopupMenuItem(value: a, child: Text(a))),
            ],
          ),
        ],
      ),
      body: _isLoading && _history.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('Nenhuma questão respondida ainda'))
              : RefreshIndicator(
                  onRefresh: () => _loadHistory(refresh: true),
                  child: ListView.builder(
                    itemCount: _history.length + (_history.length < _total ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _history.length) {
                        _loadHistory();
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final item = _history[index];
                      
                      try {
                        // O campo 'correct' vem como int (1 ou 0) do backend, precisa converter para bool
                        final correctValue = item['correct'];
                        final correct = correctValue is bool 
                            ? correctValue 
                            : (correctValue is int 
                                ? correctValue == 1 
                                : (correctValue == true || correctValue == 1));
                        final pergunta = item['pergunta'] as String? ?? '';
                        final assunto = item['assunto'] as String? ?? '';
                        final answerGiven = item['answer_given'] as String? ?? '';
                        final respostaCorreta = item['resposta_correta'] as String? ?? '';
                        final explicacao = item['explicacao'] as String?;
                        final questionId = item['question_id'] as int?;

                        return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: correct ? Colors.green : Colors.red,
                            child: Icon(
                              correct ? Icons.check : Icons.close,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            pergunta,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '$assunto • ${correct ? "Correta" : "Incorreta"}',
                            style: TextStyle(
                              color: correct ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: questionId != null
                              ? IconButton(
                                  icon: const Icon(Icons.refresh),
                                  tooltip: 'Resetar',
                                  onPressed: () => _resetQuestion(questionId),
                                )
                              : null,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sua resposta: $answerGiven',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: correct ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  Text('Resposta correta: $respostaCorreta'),
                                  if (explicacao != null) ...[
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Explicação:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(explicacao),
                                  ],
                                  if (questionId != null) ...[
                                    const SizedBox(height: 16),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () {
                                            context.push('/questions/detail/$questionId');
                                          },
                                          icon: const Icon(Icons.info_outline),
                                          label: const Text('Ver Questão'),
                                        ),
                                        TextButton.icon(
                                          onPressed: () {
                                            context.push('/questions/comments/$questionId');
                                          },
                                          icon: const Icon(Icons.comment_outlined),
                                          label: const Text('Comentários'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        );
                      } catch (e, stackTrace) {
                        debugPrint('❌ Erro ao renderizar item do histórico: $e');
                        debugPrint('   Stack trace: $stackTrace');
                        debugPrint('   Item: $item');
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.red.shade50,
                          child: ListTile(
                            leading: const Icon(Icons.error_outline, color: Colors.red),
                            title: const Text('Erro ao carregar questão'),
                            subtitle: Text('ID: ${item['id'] ?? 'N/A'}'),
                          ),
                        );
                      }
                    },
                  ),
                ),
    );
  }
}

