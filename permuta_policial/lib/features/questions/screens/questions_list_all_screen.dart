// /lib/features/questions/screens/questions_list_all_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/questions_provider.dart';
import '../../../core/models/question.dart';
import '../widgets/subject_tree_selector.dart';

class QuestionsListAllScreen extends StatefulWidget {
  const QuestionsListAllScreen({super.key});

  @override
  State<QuestionsListAllScreen> createState() => _QuestionsListAllScreenState();
}

class _QuestionsListAllScreenState extends State<QuestionsListAllScreen> {
  List<Question> _questions = [];
  String? _assuntoSelecionado;
  String? _subassuntoSelecionado;
  String? _tipoSelecionado;
  bool _isLoading = false;
  int _currentPage = 1;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedSubjects = {};
  final Set<String> _selectedSubassuntos = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _loadQuestions({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 1;
    }

    setState(() => _isLoading = true);
    try {
      final provider = context.read<QuestionsProvider>();
      await provider.loadQuestions(
        assunto: _assuntoSelecionado,
        subassunto: _subassuntoSelecionado,
        tipo: _tipoSelecionado,
        page: _currentPage,
        perPage: 20,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );

      if (mounted) {
        setState(() {
          _questions = provider.questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar questões: $e')),
        );
      }
    }
  }


  void _clearFilters() {
    setState(() {
      _assuntoSelecionado = null;
      _subassuntoSelecionado = null;
      _tipoSelecionado = null;
      _searchController.clear();
      _selectedSubjects.clear();
      _selectedSubassuntos.clear();
      _loadQuestions(resetPage: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Questões'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadQuestions(resetPage: true),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Busca
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadQuestions(resetPage: true);
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _loadQuestions(resetPage: true),
                ),
                const SizedBox(height: 16),
                // Filtro de Tipo
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _tipoSelecionado,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos')),
                          DropdownMenuItem(value: 'mc', child: Text('Múltipla Escolha (MC)')),
                          DropdownMenuItem(value: 'vf', child: Text('Verdadeiro/Falso (VF)')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _tipoSelecionado = value;
                          });
                          _loadQuestions(resetPage: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Limpar Filtros'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filtro de Assunto/Subassunto (Árvore)
                const Text(
                  'Assuntos e Subassuntos:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
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
                        
                        // Se apenas um assunto e um subassunto selecionados, usa para filtro
                        if (subjects.length == 1 && subassuntos.length == 1) {
                          _assuntoSelecionado = subjects.first;
                          _subassuntoSelecionado = subassuntos.first;
                        } else if (subjects.length == 1 && subassuntos.isEmpty) {
                          _assuntoSelecionado = subjects.first;
                          _subassuntoSelecionado = null;
                        } else if (subjects.isEmpty && subassuntos.isEmpty) {
                          _assuntoSelecionado = null;
                          _subassuntoSelecionado = null;
                        } else {
                          // Múltiplas seleções - não aplica filtro específico
                          _assuntoSelecionado = null;
                          _subassuntoSelecionado = null;
                        }
                        _loadQuestions(resetPage: true);
                      });
                      },
                    ),
                  ),
                if (_assuntoSelecionado != null || _subassuntoSelecionado != null || _tipoSelecionado != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (_assuntoSelecionado != null)
                          Chip(
                            label: Text('Assunto: $_assuntoSelecionado'),
                            onDeleted: () {
                              setState(() {
                                _assuntoSelecionado = null;
                                _subassuntoSelecionado = null;
                                _selectedSubjects.clear();
                                _selectedSubassuntos.clear();
                              });
                              _loadQuestions(resetPage: true);
                            },
                          ),
                        if (_subassuntoSelecionado != null)
                          Chip(
                            label: Text('Subassunto: $_subassuntoSelecionado'),
                            onDeleted: () {
                              setState(() {
                                _subassuntoSelecionado = null;
                              });
                              _loadQuestions(resetPage: true);
                            },
                          ),
                        if (_tipoSelecionado != null)
                          Chip(
                            label: Text('Tipo: ${_tipoSelecionado!.toUpperCase()}'),
                            onDeleted: () {
                              setState(() {
                                _tipoSelecionado = null;
                              });
                              _loadQuestions(resetPage: true);
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Lista de questões
          Expanded(
            child: _isLoading && _questions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _questions.isEmpty
                    ? const Center(
                        child: Text('Nenhuma questão encontrada'),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadQuestions(resetPage: true),
                        child: ListView.builder(
                          itemCount: _questions.length,
                          itemBuilder: (context, index) {
                            final question = _questions[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                title: Text(
                                  question.pergunta,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Chip(
                                          label: Text(question.assunto),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        if (question.subassunto != null) ...[
                                          const SizedBox(width: 4),
                                          Chip(
                                            label: Text(question.subassunto!),
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ],
                                        const SizedBox(width: 4),
                                        Chip(
                                          label: Text(
                                            question.tipo.toUpperCase(),
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  // Navegar para detalhes da questão
                                  // Navigator.push(...)
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

