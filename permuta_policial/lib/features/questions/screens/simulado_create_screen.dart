import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/questions_provider.dart';
import 'package:go_router/go_router.dart';
import '../widgets/subject_tree_selector.dart';
import '../../auth/providers/auth_provider.dart';

class SimuladoCreateScreen extends StatefulWidget {
  const SimuladoCreateScreen({super.key});

  @override
  State<SimuladoCreateScreen> createState() => _SimuladoCreateScreenState();
}

class _SimuladoCreateScreenState extends State<SimuladoCreateScreen> {
  String _selectedType = 'random';
  int _questionCount = 10;
  final Map<String, int> _subjectsCount = {};
  final TextEditingController _tituloController = TextEditingController();
  List<String> _availableSubjects = [];
  int _maxQuestions = 10;
  bool _isLoading = false;
  final Set<String> _selectedSubassuntos = {};
  String? _selectedTipo;
  

  @override
  void initState() {
    super.initState();
    _loadOptions();
    // Verifica status premium quando a tela é construída
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Se o usuário não estiver carregado, tenta recarregar
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user == null && authProvider.isAuthenticated) {
        debugPrint('⚠️ SimuladoCreateScreen: Usuário não carregado, recarregando perfil...');
        try {
          await authProvider.refreshProfile();
        } catch (e) {
          debugPrint('❌ Erro ao recarregar perfil: $e');
        }
      }
      _updateMaxQuestions();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Atualiza quando o status premium mudar
    final authProvider = context.watch<AuthProvider>();
    final isPremium = authProvider.user?.isPremium ?? false;
    final expectedMax = isPremium ? 120 : 10;
    if (_maxQuestions != expectedMax && mounted) {
      _updateMaxQuestions();
    }
  }

  void _updateMaxQuestions() {
    final authProvider = context.read<AuthProvider>();
    final isPremium = authProvider.user?.isPremium ?? false;
    if (mounted) {
      setState(() {
        final newMax = isPremium ? 120 : 10;
        debugPrint('🔧 SimuladoCreateScreen: Atualizando _maxQuestions');
        debugPrint('   - isPremium: $isPremium');
        debugPrint('   - _maxQuestions atual: $_maxQuestions');
        debugPrint('   - _maxQuestions novo: $newMax');
        _maxQuestions = newMax;
        // Ajusta a quantidade de questões se necessário
        if (_questionCount > _maxQuestions) {
          _questionCount = _maxQuestions;
        } else if (_questionCount < 1) {
          _questionCount = 1;
        }
        debugPrint('   - _questionCount: $_questionCount');
      });
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<QuestionsProvider>();
      final options = await provider.getCreateOptions();
      
      if (options != null && mounted) {
        // Verifica se o usuário é premium
        final authProvider = context.read<AuthProvider>();
        final isPremium = authProvider.user?.isPremium ?? false;
        
        setState(() {
          _availableSubjects = (options['subjects'] as List<dynamic>?)
                  ?.map((s) => s.toString())
                  .toList() ??
              [
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
          final maxQuestionsMap = options['maxQuestions'] as Map<String, dynamic>?;
          final newMax = isPremium 
              ? (maxQuestionsMap?['premium'] as int? ?? 120)
              : (maxQuestionsMap?['free'] as int? ?? 10);
          _maxQuestions = newMax;
          // Ajusta a quantidade se necessário
          if (_questionCount > _maxQuestions) {
            _questionCount = _maxQuestions;
          }
        });
      } else {
        // Fallback para valores padrão
        final authProvider = context.read<AuthProvider>();
        final isPremium = authProvider.user?.isPremium ?? false;
        setState(() {
          _availableSubjects = [
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
          final newMax = isPremium ? 120 : 10;
          _maxQuestions = newMax;
          // Ajusta a quantidade se necessário
          if (_questionCount > _maxQuestions) {
            _questionCount = _maxQuestions;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar opções: $e')),
        );
        // Fallback para valores padrão
        final authProvider = context.read<AuthProvider>();
        final isPremium = authProvider.user?.isPremium ?? false;
        setState(() {
          _availableSubjects = [
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
          final newMax = isPremium ? 120 : 10;
          _maxQuestions = newMax;
          // Ajusta a quantidade se necessário
          if (_questionCount > _maxQuestions) {
            _questionCount = _maxQuestions;
          }
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createSimulado() async {
    if (_selectedType == 'by_subject' && _subjectsCount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um assunto')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final provider = context.read<QuestionsProvider>();
      final simulado = await provider.createSimulado(
        type: _selectedType,
        questionCount: _selectedType == 'random' ? _questionCount : null,
        subjects: _selectedType == 'by_subject' ? _subjectsCount : null,
        subassuntos: _selectedSubassuntos.isEmpty ? null : _selectedSubassuntos.toList(),
        tipo: _selectedTipo,
        titulo: _tituloController.text.trim().isEmpty 
            ? null 
            : _tituloController.text.trim(),
      );

      if (simulado != null && mounted) {
        // Inicia o simulado automaticamente
        final startResult = await provider.startSimulado(simulado.id!);
        if (startResult != null && mounted) {
          context.go('/simulado/play/${simulado.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar simulado: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Simulado'),
      ),
      body: _isLoading && _availableSubjects.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Título do Simulado (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tipo de Simulado',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<String>(
                    groupValue: _selectedType,
                    onChanged: (value) {
                      setState(() => _selectedType = value!);
                    },
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Aleatório'),
                          subtitle: const Text('Questões aleatórias de todos os assuntos'),
                          value: 'random',
                        ),
                        RadioListTile<String>(
                          title: const Text('Por Assunto'),
                          subtitle: const Text('Escolha os assuntos e quantidade de cada'),
                          value: 'by_subject',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_selectedType == 'random') ...[
                    const Text(
                      'Quantidade de Questões',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        // Obtém o status premium diretamente do provider
                        final authProvider = context.watch<AuthProvider>();
                        final user = authProvider.user;
                        final isPremium = user?.isPremium ?? false;
                        final currentMax = isPremium ? 120 : 10;
                        
                        // Debug
                        debugPrint('🔍 SimuladoCreateScreen: Status Premium');
                        debugPrint('   - user: ${user != null ? "existe" : "null"}');
                        debugPrint('   - user.id: ${user?.id}');
                        debugPrint('   - user.isPremium: ${user?.isPremium}');
                        debugPrint('   - isPremium (final): $isPremium');
                        debugPrint('   - currentMax: $currentMax');
                        debugPrint('   - _maxQuestions: $_maxQuestions');
                        
                        // Sincroniza o estado interno se necessário
                        if (currentMax != _maxQuestions) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _maxQuestions = currentMax;
                                if (_questionCount > _maxQuestions) {
                                  _questionCount = _maxQuestions;
                                }
                              });
                            }
                          });
                        }
                        
                        // Garante que o valor atual está dentro do range
                        final clampedValue = _questionCount.clamp(1, currentMax);
                        if (clampedValue != _questionCount) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _questionCount = clampedValue;
                              });
                            }
                          });
                        }
                        
                        // Calcula divisões: para 120 questões, usa 23 divisões (5 em 5)
                        // Para 10 questões, usa 9 divisões (1 em 1)
                        final divisions = currentMax <= 10 
                            ? currentMax - 1 
                            : ((currentMax - 1) ~/ 5); // Divisões de 5 em 5
                        
                        return Column(
                          children: [
                    Slider(
                              value: clampedValue.toDouble(),
                              min: 1.0,
                              max: currentMax.toDouble(),
                              divisions: divisions,
                              label: '$clampedValue questões',
                      onChanged: (value) {
                                final newValue = value.round().clamp(1, currentMax);
                                setState(() {
                                  _questionCount = newValue;
                                });
                      },
                    ),
                    Text(
                              '$clampedValue questões (máximo: $currentMax)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                            ),
                            if (isPremium)
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '✨ Você pode criar simulados com até 120 questões',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                  if (_selectedType == 'by_subject') ...[
                    const Text(
                      'Assuntos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._availableSubjects.map((subject) {
                      final count = _subjectsCount[subject] ?? 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(subject),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: count > 0
                                    ? () {
                                        setState(() {
                                          if (count > 1) {
                                            _subjectsCount[subject] = count - 1;
                                          } else {
                                            _subjectsCount.remove(subject);
                                          }
                                        });
                                      }
                                    : null,
                              ),
                              Text('$count', style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    _subjectsCount[subject] = (count + 1);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ${_subjectsCount.values.fold(0, (a, b) => a + b)} questões',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Filtros adicionais
                  const Text(
                    'Filtros Adicionais',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tipo:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                      setState(() => _selectedTipo = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Subassuntos (opcional):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 250,
                    child: SubjectTreeSelector(
                      selectedSubjects: {},
                      selectedSubassuntos: _selectedSubassuntos,
                      provider: context.read<QuestionsProvider>(),
                      onChanged: (subjects, subassuntos) {
                        setState(() {
                          _selectedSubassuntos.clear();
                          _selectedSubassuntos.addAll(subassuntos);
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createSimulado,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Criar e Iniciar Simulado'),
                  ),
                ],
              ),
            ),
    );
  }
}

