// /lib/features/forum/screens/forum_moderacao_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/forum_provider.dart';
import 'forum_topico_screen.dart';

class ForumModeracaoScreen extends StatefulWidget {
  const ForumModeracaoScreen({super.key});

  @override
  State<ForumModeracaoScreen> createState() => _ForumModeracaoScreenState();
}

class _ForumModeracaoScreenState extends State<ForumModeracaoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _carregarDados() {
    final provider = Provider.of<ForumProvider>(context, listen: false);
    provider.loadTopicosPendentes();
    provider.loadRespostasPendentes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderação do Fórum'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tópicos Pendentes', icon: Icon(Icons.topic)),
            Tab(text: 'Respostas Pendentes', icon: Icon(Icons.comment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTopicosPendentes(),
          _buildRespostasPendentes(),
        ],
      ),
    );
  }

  Widget _buildTopicosPendentes() {
    return Consumer<ForumProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.topicosPendentes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && provider.topicosPendentes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(provider.errorMessage!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.loadTopicosPendentes();
                  },
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        if (provider.topicosPendentes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'Nenhum tópico pendente de moderação',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadTopicosPendentes(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.topicosPendentes.length,
            itemBuilder: (context, index) {
              final topico = provider.topicosPendentes[index];
              return _buildTopicoCard(context, topico, provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildRespostasPendentes() {
    return Consumer<ForumProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.respostasPendentes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && provider.respostasPendentes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(provider.errorMessage!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.loadRespostasPendentes();
                  },
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        if (provider.respostasPendentes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'Nenhuma resposta pendente de moderação',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadRespostasPendentes(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.respostasPendentes.length,
            itemBuilder: (context, index) {
              final resposta = provider.respostasPendentes[index];
              return _buildRespostaCard(context, resposta, provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildTopicoCard(BuildContext context, Map<String, dynamic> topico, ForumProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ForumTopicoScreen(topicoId: topico['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      topico['titulo'] ?? 'Sem título',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PENDENTE',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                topico['conteudo'] ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Por: ${topico['autor_nome'] ?? 'Desconhecido'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    label: const Text('Aprovar'),
                    onPressed: () => _aprovarTopico(context, topico['id'], provider),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text('Rejeitar'),
                    onPressed: () => _rejeitarTopico(context, topico['id'], provider),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRespostaCard(BuildContext context, Map<String, dynamic> resposta, ForumProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Resposta ao tópico: ${resposta['topico_titulo'] ?? 'Desconhecido'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PENDENTE',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              resposta['conteudo'] ?? '',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Por: ${resposta['autor_nome'] ?? 'Desconhecido'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  label: const Text('Aprovar'),
                  onPressed: () => _aprovarResposta(context, resposta['id'], provider),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('Rejeitar'),
                  onPressed: () => _rejeitarResposta(context, resposta['id'], provider),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _aprovarTopico(BuildContext context, int topicoId, ForumProvider provider) async {
    final success = await provider.aprovarTopico(topicoId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tópico aprovado com sucesso!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erro ao aprovar tópico'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejeitarTopico(BuildContext context, int topicoId, ForumProvider provider) async {
    final motivoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeitar Tópico'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Informe o motivo da rejeição:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O motivo é obrigatório';
                  }
                  if (value.trim().length < 5) {
                    return 'O motivo deve ter pelo menos 5 caracteres';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await provider.rejeitarTopico(topicoId, motivoController.text.trim());
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tópico rejeitado.')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Erro ao rejeitar tópico'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _aprovarResposta(BuildContext context, int respostaId, ForumProvider provider) async {
    final success = await provider.aprovarResposta(respostaId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resposta aprovada com sucesso!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erro ao aprovar resposta'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejeitarResposta(BuildContext context, int respostaId, ForumProvider provider) async {
    final motivoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeitar Resposta'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Informe o motivo da rejeição:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O motivo é obrigatório';
                  }
                  if (value.trim().length < 5) {
                    return 'O motivo deve ter pelo menos 5 caracteres';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await provider.rejeitarResposta(respostaId, motivoController.text.trim());
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resposta rejeitada.')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Erro ao rejeitar resposta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

