// /lib/features/forum/screens/forum_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/forum_provider.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';
import 'forum_topico_screen.dart';
import 'forum_create_topico_screen.dart';
import 'forum_moderacao_screen.dart';

class ForumListScreen extends StatefulWidget {
  const ForumListScreen({super.key});

  @override
  State<ForumListScreen> createState() => _ForumListScreenState();
}

class _ForumListScreenState extends State<ForumListScreen> {
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fórum'),
        actions: [
          Consumer<DashboardProvider>(
            builder: (context, dashboardProvider, child) {
              final isAdmin = dashboardProvider.userData?.isEmbaixador ?? false;
              if (isAdmin) {
                return IconButton(
                  icon: const Icon(Icons.admin_panel_settings),
                  tooltip: 'Moderação',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => const ForumModeracaoScreen(),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => const ForumCreateTopicoScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ForumProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.categorias.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar tópicos...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              if (provider.categoriaSelecionada != null) {
                                provider.loadTopicos(provider.categoriaSelecionada!);
                              }
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (value.length >= 3) {
                      provider.searchTopicos(value);
                    } else if (value.isEmpty && provider.categoriaSelecionada != null) {
                      provider.loadTopicos(provider.categoriaSelecionada!);
                    }
                  },
                  onSubmitted: (value) {
                    if (value.length >= 3) {
                      provider.searchTopicos(value);
                    }
                  },
                ),
              ),
              if (provider.categorias.isNotEmpty)
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: provider.categorias.length,
                    itemBuilder: (context, index) {
                      final categoria = provider.categorias[index];
                      final isSelected = provider.categoriaSelecionada == categoria['id'];
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(categoria['nome'] ?? ''),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              provider.loadTopicos(categoria['id']);
                            }
                          },
                          avatar: Icon(
                            _getIconData(categoria['icone'] ?? 'forum'),
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Expanded(
                child: provider.isLoading && provider.topicos.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : provider.topicos.isEmpty
                        ? const Center(
                            child: Text('Nenhum tópico encontrado.\nSeja o primeiro a criar um!'),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              if (provider.categoriaSelecionada != null) {
                                await provider.loadTopicos(provider.categoriaSelecionada!);
                              }
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: provider.topicos.length,
                              itemBuilder: (context, index) {
                                final topico = provider.topicos[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: topico['fixado'] == true
                                        ? const Icon(Icons.push_pin, color: Colors.orange)
                                        : const Icon(Icons.forum),
                                    title: Text(
                                      topico['titulo'] ?? '',
                                      style: TextStyle(
                                        fontWeight: topico['fixado'] == true
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          topico['autor_nome'] ?? 'Autor desconhecido',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.comment, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${topico['total_respostas'] ?? 0} respostas',
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${topico['visualizacoes'] ?? 0} visualizações',
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (ctx) => ForumTopicoScreen(
                                            topicoId: topico['id'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
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

