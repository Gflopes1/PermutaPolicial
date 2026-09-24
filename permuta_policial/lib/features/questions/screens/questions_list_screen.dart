import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_router.dart';
import '../../../shared/widgets/app_bar_helper.dart';

class QuestionsListScreen extends StatefulWidget {
  const QuestionsListScreen({super.key});

  @override
  State<QuestionsListScreen> createState() => _QuestionsListScreenState();
}

class _QuestionsListScreenState extends State<QuestionsListScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questões'),
        actions: [
          ...AppBarHelper.adicionarBotaoRelatarProblema(context),
        ],
      ),
      body: Column(
        children: [
          // Botões de ação
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push(AppRoutes.practice);
                    },
                    icon: const Icon(Icons.school),
                    label: const Text('Resolver Questões'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.push(AppRoutes.simuladoCreate);
                        },
                        icon: const Icon(Icons.quiz),
                        label: const Text('Criar Simulado'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.push(AppRoutes.practiceHistory);
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('Histórico'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Use os botões acima para começar',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

