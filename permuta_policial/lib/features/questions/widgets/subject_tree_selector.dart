import 'package:flutter/material.dart';
import '../providers/questions_provider.dart';

class SubjectTreeSelector extends StatefulWidget {
  final Set<String> selectedSubjects;
  final Set<String> selectedSubassuntos;
  final Function(Set<String> subjects, Set<String> subassuntos) onChanged;
  final QuestionsProvider provider;

  const SubjectTreeSelector({
    super.key,
    required this.selectedSubjects,
    required this.selectedSubassuntos,
    required this.onChanged,
    required this.provider,
  });

  @override
  State<SubjectTreeSelector> createState() => _SubjectTreeSelectorState();
}

class _SubjectTreeSelectorState extends State<SubjectTreeSelector> {
  final Map<String, bool> _expandedSubjects = {};
  final Map<String, List<String>> _subassuntosCache = {};
  final Map<String, bool> _loadingSubassuntos = {};
  List<String> _allAssuntos = [];
  bool _isLoadingAssuntos = false;
  late Set<String> _localSelectedSubjects;
  late Set<String> _localSelectedSubassuntos;

  @override
  void initState() {
    super.initState();
    // Cria cópias locais dos Sets para evitar modificar diretamente os do widget pai
    _localSelectedSubjects = Set<String>.from(widget.selectedSubjects);
    _localSelectedSubassuntos = Set<String>.from(widget.selectedSubassuntos);
    _loadAssuntos();
  }

  @override
  void didUpdateWidget(SubjectTreeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Atualiza os Sets locais se o widget pai mudou
    if (oldWidget.selectedSubjects != widget.selectedSubjects) {
      _localSelectedSubjects = Set<String>.from(widget.selectedSubjects);
    }
    if (oldWidget.selectedSubassuntos != widget.selectedSubassuntos) {
      _localSelectedSubassuntos = Set<String>.from(widget.selectedSubassuntos);
    }
  }

  Future<void> _loadAssuntos() async {
    setState(() => _isLoadingAssuntos = true);
    try {
      final assuntos = await widget.provider.getAllAssuntos();
      if (mounted) {
        setState(() {
          _allAssuntos = assuntos;
          _isLoadingAssuntos = false;
        });
        if (assuntos.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhum assunto disponível no momento'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAssuntos = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar assuntos: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _loadSubassuntos(String assunto) async {
    if (_subassuntosCache.containsKey(assunto)) return;

    setState(() => _loadingSubassuntos[assunto] = true);
    try {
      final subassuntos = await widget.provider.getSubassuntosByAssunto(assunto);
      setState(() {
        _subassuntosCache[assunto] = subassuntos;
        _loadingSubassuntos[assunto] = false;
      });
    } catch (e) {
      setState(() => _loadingSubassuntos[assunto] = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar subassuntos: $e')),
        );
      }
    }
  }

  void _toggleSubject(String assunto) {
    setState(() {
      _expandedSubjects[assunto] = !(_expandedSubjects[assunto] ?? false);
      if (_expandedSubjects[assunto] == true) {
        _loadSubassuntos(assunto);
      }
    });
  }

  void _toggleSubjectSelection(String assunto) {
    setState(() {
      if (_localSelectedSubjects.contains(assunto)) {
        _localSelectedSubjects.remove(assunto);
        // Remove subassuntos relacionados
        final subassuntos = _subassuntosCache[assunto] ?? [];
        _localSelectedSubassuntos.removeWhere((s) => subassuntos.contains(s));
      } else {
        _localSelectedSubjects.add(assunto);
      }
      // Notifica o widget pai com cópias dos Sets
      widget.onChanged(
        Set<String>.from(_localSelectedSubjects),
        Set<String>.from(_localSelectedSubassuntos),
      );
    });
  }

  void _toggleSubassunto(String assunto, String subassunto) {
    setState(() {
      if (_localSelectedSubassuntos.contains(subassunto)) {
        _localSelectedSubassuntos.remove(subassunto);
      } else {
        _localSelectedSubassuntos.add(subassunto);
        // Garante que o assunto também está selecionado
        if (!_localSelectedSubjects.contains(assunto)) {
          _localSelectedSubjects.add(assunto);
        }
      }
      // Notifica o widget pai com cópias dos Sets
      widget.onChanged(
        Set<String>.from(_localSelectedSubjects),
        Set<String>.from(_localSelectedSubassuntos),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAssuntos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allAssuntos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Nenhum assunto disponível', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _allAssuntos.length,
      itemBuilder: (context, index) {
        final assunto = _allAssuntos[index];
        final isExpanded = _expandedSubjects[assunto] ?? false;
        final isSelected = _localSelectedSubjects.contains(assunto);
        final subassuntos = _subassuntosCache[assunto] ?? [];
        final isLoadingSub = _loadingSubassuntos[assunto] ?? false;

        return Column(
          children: [
            ListTile(
              leading: Checkbox(
                value: isSelected,
                onChanged: (value) {
                  _toggleSubjectSelection(assunto);
                },
              ),
              title: GestureDetector(
                onTap: () => _toggleSubjectSelection(assunto),
                child: Text(assunto),
              ),
              trailing: GestureDetector(
                onTap: () => _toggleSubject(assunto),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 24,
                  ),
                ),
              ),
              onTap: () => _toggleSubjectSelection(assunto),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: isLoadingSub
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : subassuntos.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Nenhum subassunto disponível', style: TextStyle(color: Colors.grey)),
                          )
                        : Column(
                            children: subassuntos.map((subassunto) {
                              final isSubSelected = _localSelectedSubassuntos.contains(subassunto);
                              return CheckboxListTile(
                                value: isSubSelected,
                                onChanged: (value) => _toggleSubassunto(assunto, subassunto),
                                title: Text(subassunto, style: const TextStyle(fontSize: 14)),
                                dense: true,
                              );
                            }).toList(),
                          ),
              ),
          ],
        );
      },
    );
  }
}

