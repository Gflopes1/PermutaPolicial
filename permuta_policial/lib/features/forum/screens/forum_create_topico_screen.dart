// /lib/features/forum/screens/forum_create_topico_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/forum_provider.dart';

class ForumCreateTopicoScreen extends StatefulWidget {
  const ForumCreateTopicoScreen({super.key});

  @override
  State<ForumCreateTopicoScreen> createState() => _ForumCreateTopicoScreenState();
}

class _ForumCreateTopicoScreenState extends State<ForumCreateTopicoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _conteudoController = TextEditingController();
  int? _categoriaSelecionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ForumProvider>(context, listen: false);
      provider.loadCategorias();
    });
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _conteudoController.dispose();
    super.dispose();
  }

  Future<void> _criarTopico() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria')),
      );
      return;
    }

    final provider = Provider.of<ForumProvider>(context, listen: false);
    final success = await provider.createTopico(
      categoriaId: _categoriaSelecionada!,
      titulo: _tituloController.text.trim(),
      conteudo: _conteudoController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tópico criado com sucesso!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erro ao criar tópico'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Tópico'),
        actions: [
          TextButton(
            onPressed: _criarTopico,
            child: const Text('Publicar'),
          ),
        ],
      ),
      body: Consumer<ForumProvider>(
        builder: (context, provider, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Seleção de categoria
                DropdownButtonFormField<int>(
                  initialValue: _categoriaSelecionada,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: provider.categorias.map((categoria) {
                    return DropdownMenuItem<int>(
                      value: categoria['id'],
                      child: Row(
                        children: [
                          Icon(_getIconData(categoria['icone'] ?? 'forum')),
                          const SizedBox(width: 8),
                          Text(categoria['nome'] ?? ''),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoriaSelecionada = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione uma categoria';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Título
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 255,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'O título é obrigatório';
                    }
                    if (value.trim().length < 3) {
                      return 'O título deve ter pelo menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Conteúdo
                TextFormField(
                  controller: _conteudoController,
                  decoration: const InputDecoration(
                    labelText: 'Conteúdo',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 10,
                  maxLength: 10000,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'O conteúdo é obrigatório';
                    }
                    if (value.trim().length < 10) {
                      return 'O conteúdo deve ter pelo menos 10 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: provider.isLoading ? null : _criarTopico,
                  child: provider.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Publicar Tópico'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'help':
        return Icons.help;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'announcement':
        return Icons.announcement;
      default:
        return Icons.forum;
    }
  }
}


