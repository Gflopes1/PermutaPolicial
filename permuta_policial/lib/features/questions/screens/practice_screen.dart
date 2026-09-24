import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/questions_provider.dart';
import '../../../core/models/question.dart';
import '../widgets/subject_tree_selector.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  Question? _currentQuestion;
  String? _selectedAnswer;
  bool _showAnswer = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  DateTime? _questionStartTime;
  final Set<String> _selectedSubjects = {};
  final Set<String> _selectedSubassuntos = {};
  String? _selectedTipo;

  // Assuntos e subassuntos agora vêm do backend via SubjectTreeSelector

  @override
  void initState() {
    super.initState();
    _loadNextQuestion();
  }

  Future<void> _loadNextQuestion() async {
    setState(() {
      _isLoading = true;
      _currentQuestion = null;
      _selectedAnswer = null;
      _showAnswer = false;
      _questionStartTime = DateTime.now();
    });

    try {
      final provider = context.read<QuestionsProvider>();
      final question = await provider.getNextPracticeQuestion(
        subjects: _selectedSubjects.isEmpty ? null : _selectedSubjects.toList(),
        subassuntos: _selectedSubassuntos.isEmpty ? null : _selectedSubassuntos.toList(),
        tipo: _selectedTipo,
      );

      if (question != null && mounted) {
        setState(() {
          _currentQuestion = question;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma questão disponível. Tente resetar algumas questões no histórico.'),
          ),
        );
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

  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null || _currentQuestion == null) return;

    setState(() => _isSubmitting = true);

    try {
      final timeSpent = DateTime.now().difference(_questionStartTime!).inSeconds;
      final provider = context.read<QuestionsProvider>();
      await provider.savePracticeAnswer(
        questionId: _currentQuestion!.id!,
        answerGiven: _selectedAnswer!,
        timeSpentSeconds: timeSpent,
      );

      setState(() {
        _showAnswer = true;
        _isSubmitting = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  void _nextQuestion() {
    _loadNextQuestion();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Praticar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showSubjectFilter(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentQuestion == null
              ? const Center(child: Text('Nenhuma questão disponível'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Pergunta
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentQuestion!.pergunta,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_currentQuestion!.assunto}${_currentQuestion!.subassunto != null ? ' • ${_currentQuestion!.subassunto}' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Alternativas
                      ..._currentQuestion!.alternativas.asMap().entries.map((entry) {
                        final index = entry.key;
                        final alternativa = entry.value;
                        final letter = String.fromCharCode(97 + index);
                        final isSelected = _selectedAnswer == letter;
                        // Para questões VF, normaliza resposta correta (C/E -> a/b)
                        final respostaCorretaNormalizada = _normalizeRespostaCorreta(
                          _currentQuestion!.respostaCorreta,
                          _currentQuestion!.tipo,
                          _currentQuestion!.alternativas.length,
                        );
                        final isCorrect = letter.toLowerCase() == respostaCorretaNormalizada.toLowerCase();
                        final showResult = _showAnswer;

                        Color? cardColor;
                        IconData? icon;
                        Color? iconColor;

                        if (showResult) {
                          if (isCorrect) {
                            cardColor = Colors.green.withAlpha(26);
                            icon = Icons.check_circle;
                            iconColor = Colors.green;
                          } else if (isSelected && !isCorrect) {
                            cardColor = Colors.red.withAlpha(26);
                            icon = Icons.cancel;
                            iconColor = Colors.red;
                          }
                        } else if (isSelected) {
                          cardColor = Theme.of(context).primaryColor.withAlpha(26);
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: cardColor,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: showResult && isCorrect
                                  ? Colors.green
                                  : showResult && isSelected && !isCorrect
                                      ? Colors.red
                                      : isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[300],
                              child: Text(
                                letter.toUpperCase(),
                                style: TextStyle(
                                  color: isSelected || (showResult && isCorrect)
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(alternativa),
                            trailing: showResult && icon != null
                                ? Icon(icon, color: iconColor)
                                : null,
                            onTap: _showAnswer || _isSubmitting
                                ? null
                                : () {
                                    setState(() => _selectedAnswer = letter);
                                  },
                          ),
                        );
                      }),
                      if (_showAnswer && _currentQuestion!.explicacao != null) ...[
                        const SizedBox(height: 16),
                        Card(
                            color: Colors.blue.withAlpha(26),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Explicação',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(_currentQuestion!.explicacao!),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (!_showAnswer)
                        ElevatedButton(
                          onPressed: _isSubmitting || _selectedAnswer == null
                              ? null
                              : _submitAnswer,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Verificar Resposta'),
                        )
                      else ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.push('/questions/comments/${_currentQuestion!.id}');
                                },
                                icon: const Icon(Icons.comment_outlined),
                                label: const Text('Comentários'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _nextQuestion,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Próxima'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  void _showSubjectFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                    setState(() {
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
                      setState(() {
                        _selectedSubjects.clear();
                        _selectedSubjects.addAll(subjects);
                        _selectedSubassuntos.clear();
                        _selectedSubassuntos.addAll(subassuntos);
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
                setState(() {
                  _selectedSubjects.clear();
                  _selectedSubassuntos.clear();
                  _selectedTipo = null;
                });
              },
              child: const Text('Limpar'),
            ),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                context.pop();
                _loadNextQuestion();
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
    );
  }
}

