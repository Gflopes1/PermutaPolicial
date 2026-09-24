import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/questions_provider.dart';
import '../../../core/models/question.dart';
import '../widgets/subject_tree_selector.dart';

class QuestionsAdminScreen extends StatefulWidget {
  const QuestionsAdminScreen({super.key});

  @override
  State<QuestionsAdminScreen> createState() => _QuestionsAdminScreenState();
}

class _QuestionsAdminScreenState extends State<QuestionsAdminScreen> {
  List<Question> _pendingQuestions = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _total = 0;
  bool _hasMore = true;
  
  // Filtros
  String? _selectedTipo;
  String? _selectedAssunto;
  String? _selectedSubassunto;
  final Set<String> _selectedSubjects = {};
  final Set<String> _selectedSubassuntos = {};
  

  @override
  void initState() {
    super.initState();
    _loadPendingQuestions();
  }

  Future<void> _loadPendingQuestions({bool loadMore = false}) async {
    if (!mounted) return;
    
    // Se for carregar mais, não mostra loading principal
    if (loadMore) {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _pendingQuestions = [];
        _hasMore = true;
      });
    }

    try {
      final provider = context.read<QuestionsProvider>();
      final result = await provider.getPendingQuestions(
        page: _currentPage,
        assunto: _selectedAssunto,
        subassunto: _selectedSubassunto,
        tipo: _selectedTipo,
      );

      if (!mounted) return;

      if (result != null) {
        try {
          setState(() {
            // Verifica se result tem estrutura de paginação
            final resultMap = result as Map<String, dynamic>?;
            if (resultMap != null && resultMap.containsKey('data')) {
              final data = resultMap['data'] as List<dynamic>? ?? [];
              final newQuestions = data.map((q) {
                try {
                  return Question.fromJson(q as Map<String, dynamic>);
                } catch (e) {
                  debugPrint('Erro ao parsear questão: $e');
                  debugPrint('Dados da questão: $q');
                  return null;
                }
              }).whereType<Question>().toList();
              
              if (loadMore) {
                _pendingQuestions.addAll(newQuestions);
              } else {
                _pendingQuestions = newQuestions;
              }
              
              // Atualiza informações de paginação
              _total = resultMap['total'] is int 
                  ? resultMap['total'] as int 
                  : (resultMap['total'] is num 
                      ? (resultMap['total'] as num).toInt() 
                      : 0);
              _hasMore = _pendingQuestions.length < _total;
              if (_hasMore) {
                _currentPage++;
              }
            } else {
              debugPrint('⚠️ Estrutura de resposta inesperada para questões pendentes');
              if (!loadMore) {
                _pendingQuestions = [];
              }
            }
            _isLoading = false;
            _isLoadingMore = false;
          });
        } catch (e, stackTrace) {
          debugPrint('Erro ao processar questões pendentes: $e');
          debugPrint('Stack trace: $stackTrace');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao processar questões: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        // Se result é null, houve erro mas foi tratado no provider
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao carregar questões pendentes. Tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveQuestion(int questionId) async {
    try {
      final provider = context.read<QuestionsProvider>();
      final success = await provider.approveQuestion(questionId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Questão aprovada')),
        );
        _loadPendingQuestions(loadMore: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _rejectQuestion(int questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeitar Questão'),
        content: const Text('Deseja rejeitar esta questão?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final provider = context.read<QuestionsProvider>();
        final success = await provider.rejectQuestion(questionId);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Questão rejeitada')),
          );
          _loadPendingQuestions(loadMore: false);
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

  /// Normaliza a resposta correta para questões VF
  /// Mapeia C/E para a/b baseado na posição das alternativas
  String _normalizeRespostaCorreta(String respostaCorreta, String tipo, int numAlternativas) {
    if (tipo.toLowerCase() != 'vf' || numAlternativas != 2) {
      return respostaCorreta;
    }
    
    // Para questões VF com 2 alternativas, mapeia C/E para a/b
    final respostaUpper = respostaCorreta.toUpperCase();
    if (respostaUpper == 'C') {
      return 'a'; // Primeira alternativa
    } else if (respostaUpper == 'E') {
      return 'b'; // Segunda alternativa
    }
    // Se já for a/b, retorna como está
    return respostaCorreta.toLowerCase();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtros'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tipo:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedTipo,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Todos os tipos',
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(value: 'mc', child: Text('Múltipla Escolha')),
                      DropdownMenuItem(value: 'vf', child: Text('Verdadeiro/Falso')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedTipo = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('Assunto/Subassunto:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: SubjectTreeSelector(
                      selectedSubjects: _selectedSubjects,
                      selectedSubassuntos: _selectedSubassuntos,
                      provider: context.read<QuestionsProvider>(),
                      onChanged: (subjects, subassuntos) {
                        setDialogState(() {
                          _selectedSubjects.clear();
                          _selectedSubjects.addAll(subjects);
                          _selectedSubassuntos.clear();
                          _selectedSubassuntos.addAll(subassuntos);
                          
                          // Se apenas um assunto e um subassunto selecionados, usa para filtro
                          if (subjects.length == 1 && subassuntos.length == 1) {
                            _selectedAssunto = subjects.first;
                            _selectedSubassunto = subassuntos.first;
                          } else if (subjects.length == 1 && subassuntos.isEmpty) {
                            _selectedAssunto = subjects.first;
                            _selectedSubassunto = null;
                          } else {
                            _selectedAssunto = null;
                            _selectedSubassunto = null;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _selectedTipo = null;
                  _selectedAssunto = null;
                  _selectedSubassunto = null;
                  _selectedSubjects.clear();
                  _selectedSubassuntos.clear();
                });
              },
              child: const Text('Limpar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadPendingQuestions(loadMore: false);
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters = _selectedTipo != null || _selectedAssunto != null || _selectedSubassunto != null;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprovar Questões'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (hasFilters)
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
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: _isLoading && _pendingQuestions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _pendingQuestions.isEmpty
              ? const Center(child: Text('Nenhuma questão pendente'))
              : RefreshIndicator(
                  onRefresh: () => _loadPendingQuestions(loadMore: false),
                  child: ListView.builder(
                    itemCount: _pendingQuestions.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Carrega mais quando chega ao final
                      if (index == _pendingQuestions.length) {
                        _loadPendingQuestions(loadMore: true);
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      final question = _pendingQuestions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ExpansionTile(
                          title: Text(
                            question.pergunta,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${question.assunto}${question.subassunto != null ? ' • ${question.subassunto}' : ''} • ${question.tipo == 'mc' ? 'Múltipla Escolha' : 'Verdadeiro/Falso'}'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Questão completa
                                  const Text(
                                    'Questão:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    question.pergunta,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(height: 24),
                                  // Alternativas completas
                                  const Text(
                                    'Alternativas:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  ...question.alternativas.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final alternativa = entry.value;
                                    final letter = String.fromCharCode(97 + index);
                                    // Normaliza resposta correta para questões VF (C/E -> a/b)
                                    final respostaCorretaNormalizada = _normalizeRespostaCorreta(
                                      question.respostaCorreta,
                                      question.tipo,
                                      question.alternativas.length,
                                    );
                                    final isCorrect = letter.toLowerCase() == respostaCorretaNormalizada.toLowerCase();
                                    final theme = Theme.of(context);
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isCorrect 
                                            ? Colors.green.withValues(alpha: 0.1) 
                                            : theme.colorScheme.surface,
                                        border: Border.all(
                                          color: isCorrect ? Colors.green : theme.dividerColor,
                                          width: isCorrect ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: isCorrect ? Colors.green : Colors.grey.shade300,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                letter.toUpperCase(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isCorrect ? Colors.white : Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              alternativa,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          if (isCorrect)
                                            const Icon(Icons.check_circle, color: Colors.green, size: 24),
                                        ],
                                      ),
                                    );
                                  }),
                                  if (question.explicacao != null) ...[
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Explicação:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        question.explicacao!,
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        label: const Text('Rejeitar'),
                                        onPressed: () => _rejectQuestion(question.id!),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.check),
                                        label: const Text('Aprovar'),
                                        onPressed: () => _approveQuestion(question.id!),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

