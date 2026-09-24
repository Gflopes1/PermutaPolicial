import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/questions_provider.dart';
import 'package:go_router/go_router.dart';

class SimuladoPlayScreen extends StatefulWidget {
  final int simuladoId;

  const SimuladoPlayScreen({super.key, required this.simuladoId});

  @override
  State<SimuladoPlayScreen> createState() => _SimuladoPlayScreenState();
}

class _SimuladoPlayScreenState extends State<SimuladoPlayScreen> {
  int _currentOrdem = 1;
  Map<String, dynamic>? _currentQuestion;
  String? _selectedAnswer;
  DateTime? _questionStartTime;
  int? _serverStartTime;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _isLoading = true;
      _selectedAnswer = null;
      _questionStartTime = DateTime.now();
    });

    try {
      final provider = context.read<QuestionsProvider>();
      final result = await provider.getCurrentQuestion(widget.simuladoId, _currentOrdem);
      
      if (result != null && mounted) {
        setState(() {
          _currentQuestion = result;
          _serverStartTime = result['server_start_time'] as int?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar questão: $e')),
        );
        context.pop();
      }
    }
  }

  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma resposta')),
      );
      return;
    }

    if (_questionStartTime == null || _serverStartTime == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final timeSpent = DateTime.now().difference(_questionStartTime!).inSeconds;
      final provider = context.read<QuestionsProvider>();
      
      final result = await provider.submitAnswer(
        simuladoId: widget.simuladoId,
        questionId: _currentQuestion!['question']['id'] as int,
        ordem: _currentOrdem,
        answerGiven: _selectedAnswer!,
        timeSpentSeconds: timeSpent,
        serverStartTime: _serverStartTime!,
      );

      if (result != null && mounted) {
        final isLast = result['is_last'] as bool? ?? false;
        
        if (isLast) {
          // Última questão, vai para o resultado
          context.go('/simulado/result/${widget.simuladoId}');
        } else {
          // Próxima questão
          setState(() {
            _currentOrdem++;
          });
          _loadQuestion();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar resposta: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Questão $_currentOrdem'),
        actions: [
          if (_currentQuestion != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '${_currentQuestion!['total_questions'] ?? 0} questões',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentQuestion == null
              ? const Center(child: Text('Erro ao carregar questão'))
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
                                _currentQuestion!['question']['pergunta'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_currentQuestion!['question']['assunto'] ?? ''} • ${_currentQuestion!['question']['tipo'] ?? ''}',
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
                      if (_currentQuestion!['question']['alternativas'] != null)
                        ...(_currentQuestion!['question']['alternativas'] as List)
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key;
                          final alternativa = entry.value as String;
                          final letter = String.fromCharCode(97 + index);
                          final isSelected = _selectedAnswer == letter;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isSelected
                                ? Theme.of(context).primaryColor.withAlpha(26)
                                : null,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[300],
                                child: Text(
                                  letter.toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(alternativa),
                              onTap: _isSubmitting
                                  ? null
                                  : () {
                                      setState(() => _selectedAnswer = letter);
                                    },
                            ),
                          );
                        }),
                      const SizedBox(height: 32),
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
                            : const Text('Confirmar Resposta'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

