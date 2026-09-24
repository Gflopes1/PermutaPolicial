import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/questions_provider.dart';
import '../../../core/models/simulado.dart';
import '../../../core/config/app_router.dart';

class SimuladoResultScreen extends StatefulWidget {
  final int simuladoId;

  const SimuladoResultScreen({super.key, required this.simuladoId});

  @override
  State<SimuladoResultScreen> createState() => _SimuladoResultScreenState();
}

class _SimuladoResultScreenState extends State<SimuladoResultScreen> {
  SimuladoResult? _result;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  Future<void> _loadResult() async {
    try {
      final provider = context.read<QuestionsProvider>();
      final result = await provider.getResult(widget.simuladoId);
      
      if (result != null && mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar resultado: $e')),
        );
        setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado do Simulado'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _result == null
              ? const Center(child: Text('Erro ao carregar resultado'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Resumo
                      Card(
                        color: Theme.of(context).primaryColor.withAlpha(26),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(
                                '${_result!.correct}/${_result!.total}',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Acertos',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        '${(_result!.accuracy * 100).toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Aproveitamento',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        '${_result!.totalTime ~/ 60}min',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Tempo Total',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Detalhes das questões
                      const Text(
                        'Detalhes das Questões',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._result!.attempts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final attempt = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: attempt.correct
                              ? Colors.green.withAlpha(26)
                              : Colors.red.withAlpha(26),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: attempt.correct
                                  ? Colors.green
                                  : Colors.red,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              attempt.pergunta ?? 'Questão ${index + 1}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              attempt.correct ? 'Correta ✓' : 'Incorreta ✗',
                              style: TextStyle(
                                color: attempt.correct ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (attempt.alternativas != null) ...[
                                      const Text(
                                        'Alternativas:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      ...attempt.alternativas!.asMap().entries.map((alt) {
                                        final letter = String.fromCharCode(97 + alt.key);
                                        // Normaliza resposta correta para questões VF (C/E -> a/b)
                                        final respostaCorretaNormalizada = _normalizeRespostaCorreta(
                                          attempt.respostaCorreta ?? '',
                                          attempt.tipo ?? 'mc',
                                          attempt.alternativas?.length ?? 0,
                                        );
                                        final isCorrect = letter.toLowerCase() == respostaCorretaNormalizada.toLowerCase();
                                        final isSelected = letter.toLowerCase() == attempt.answerGiven.toLowerCase();
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            children: [
                                              Text(
                                                '$letter) ',
                                                style: TextStyle(
                                                  fontWeight: isCorrect || isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  color: isCorrect
                                                      ? Colors.green
                                                      : isSelected
                                                          ? Colors.red
                                                          : Colors.black,
                                                ),
                                              ),
                                              Expanded(child: Text(alt.value)),
                                              if (isCorrect)
                                                const Icon(Icons.check, color: Colors.green, size: 20),
                                              if (isSelected && !isCorrect)
                                                const Icon(Icons.close, color: Colors.red, size: 20),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                    if (attempt.explicacao != null) ...[
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Explicação:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(attempt.explicacao!),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tempo: ${attempt.timeSpentSeconds}s',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          context.go(AppRoutes.questions);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Voltar ao Início'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

