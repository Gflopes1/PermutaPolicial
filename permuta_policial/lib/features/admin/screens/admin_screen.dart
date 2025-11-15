// /lib/features/admin/screens/admin_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../marketplace/providers/marketplace_provider.dart';
import '../../../core/models/marketplace_item.dart';
import '../../../core/api/api_client.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      provider.loadEstatisticas();
      provider.loadSugestoes();
      provider.loadVerificacoes();
      provider.loadPoliciais();
      provider.loadParceiros();
      final marketplaceProvider = Provider.of<MarketplaceProvider>(context, listen: false);
      marketplaceProvider.loadItensAdmin();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Administração'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Estatísticas'),
            Tab(icon: Icon(Icons.people), text: 'Usuários'),
            Tab(icon: Icon(Icons.verified_user), text: 'Verificações'),
            Tab(icon: Icon(Icons.location_city), text: 'Sugestões'),
            Tab(icon: Icon(Icons.business), text: 'Anunciantes'),
            Tab(icon: Icon(Icons.store), text: 'Marketplace'),
          ],
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadEstatisticas();
                      provider.loadSugestoes();
                      provider.loadVerificacoes();
                      provider.loadPoliciais();
                      provider.loadParceiros();
                    },
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildEstatisticasTab(provider),
              _buildUsuariosTab(provider),
              _buildVerificacoesTab(provider),
              _buildSugestoesTab(provider),
              _buildAnunciantesTab(provider),
              _buildMarketplaceTab(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEstatisticasTab(AdminProvider provider) {
    if (provider.isLoading && provider.estatisticas == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = provider.estatisticas ?? {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard('Total de Policiais', stats['total_policiais']?.toString() ?? '0', Icons.people),
        const SizedBox(height: 16),
        _buildStatCard('Total de Unidades', stats['total_unidades']?.toString() ?? '0', Icons.location_city),
        const SizedBox(height: 16),
        _buildStatCard('Total de Intenções', stats['total_intencoes']?.toString() ?? '0', Icons.favorite),
        const SizedBox(height: 16),
        _buildStatCard('Verificações Pendentes', stats['verificacoes_pendentes']?.toString() ?? '0', Icons.pending),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsuariosTab(AdminProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar usuário',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              provider.loadPoliciais(search: value.isEmpty ? null : value);
            },
          ),
        ),
        Expanded(
          child: provider.isLoading && provider.policiais.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: provider.policiais.length,
                  itemBuilder: (context, index) {
                    final policial = provider.policiais[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(policial['nome']?[0] ?? '?'),
                        ),
                        title: Text(policial['nome'] ?? 'Sem nome'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${policial['email'] ?? 'N/A'}'),
                            Text('Status: ${policial['status_verificacao'] ?? 'N/A'}'),
                            if (policial['unidade_atual'] != null)
                              Text('Unidade: ${policial['unidade_atual']}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditPolicialDialog(context, provider, policial),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVerificacoesTab(AdminProvider provider) {
    if (provider.isLoading && provider.verificacoes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.verificacoes.isEmpty) {
      return const Center(child: Text('Nenhuma verificação pendente.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.verificacoes.length,
      itemBuilder: (context, index) {
        final verificacao = provider.verificacoes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(verificacao['nome'] ?? 'Sem nome'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${verificacao['email'] ?? 'N/A'}'),
                Text('Força: ${verificacao['forca_sigla'] ?? 'N/A'}'),
                Text('Data: ${verificacao['criado_em'] ?? 'N/A'}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () async {
                    final success = await provider.verificarPolicial(verificacao['id']);
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Policial verificado com sucesso!')),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () async {
                    final success = await provider.rejeitarPolicial(verificacao['id']);
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Policial rejeitado.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSugestoesTab(AdminProvider provider) {
    if (provider.isLoading && provider.sugestoes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.sugestoes.isEmpty) {
      return const Center(child: Text('Nenhuma sugestão pendente.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.sugestoes.length,
      itemBuilder: (context, index) {
        final sugestao = provider.sugestoes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: const Icon(Icons.location_city),
            title: Text(sugestao['nome_sugerido'] ?? 'Sem nome'),
            subtitle: Text('Município ID: ${sugestao['municipio_id'] ?? 'N/A'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () async {
                    final success = await provider.aprovarSugestao(sugestao['id']);
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sugestão aprovada!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.errorMessage ?? 'Erro ao aprovar sugestão'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () async {
                    final success = await provider.rejeitarSugestao(sugestao['id']);
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sugestão rejeitada.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.errorMessage ?? 'Erro ao rejeitar sugestão'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnunciantesTab(AdminProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddParceiroDialog(context, provider),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Anunciante'),
          ),
        ),
        Expanded(
          child: provider.isLoading && provider.parceiros.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : provider.parceiros.isEmpty
                  ? const Center(child: Text('Nenhum anunciante cadastrado.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.parceiros.length,
                      itemBuilder: (context, index) {
                        final parceiro = provider.parceiros[index];
                        return _buildParceiroCard(context, provider, parceiro);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildParceiroCard(BuildContext context, AdminProvider provider, dynamic parceiro) {
    // Extrai os dados com segurança
    final int id = parceiro['id'] is int ? parceiro['id'] : int.tryParse(parceiro['id']?.toString() ?? '0') ?? 0;
    final String imagemUrl = parceiro['imagem_url']?.toString() ?? '';
    final String? linkUrl = parceiro['link_url']?.toString();
    final int ordem = parceiro['ordem'] is int ? parceiro['ordem'] : int.tryParse(parceiro['ordem']?.toString() ?? '0') ?? 0;
    final bool ativo = parceiro['ativo'] == 1 || parceiro['ativo'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: imagemUrl.isNotEmpty
            ? Image.network(
                imagemUrl,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 50),
              )
            : const Icon(Icons.image, size: 50),
        title: Text('ID: $id ${!ativo ? "(Inativo)" : ""}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Link: ${linkUrl ?? 'Nenhum'}'),
            Text('Ordem: $ordem'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditParceiroDialog(
                context,
                provider,
                id,
                imagemUrl,
                linkUrl,
                ordem,
                ativo,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmarExclusaoParceiro(context, provider, id),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPolicialDialog(BuildContext context, AdminProvider provider, Map<String, dynamic> policial) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Policial'),
        content: const Text('Funcionalidade em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showAddParceiroDialog(BuildContext context, AdminProvider provider) {
    final imagemController = TextEditingController();
    final linkController = TextEditingController();
    final ordemController = TextEditingController(text: '0');
    bool ativo = true;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adicionar Anunciante'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: imagemController,
                  decoration: const InputDecoration(
                    labelText: 'URL da Imagem *',
                    hintText: 'https://exemplo.com/imagem.png',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(
                    labelText: 'URL do Link (opcional)',
                    hintText: 'https://exemplo.com',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ordemController,
                  decoration: const InputDecoration(
                    labelText: 'Ordem de Exibição',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Ativo'),
                  value: ativo,
                  onChanged: (value) {
                    setState(() {
                      ativo = value ?? true;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (imagemController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('URL da imagem é obrigatória')),
                  );
                  return;
                }
                
                final success = await provider.createParceiro({
                  'imagem_url': imagemController.text.trim(),
                  'link_url': linkController.text.trim().isEmpty ? null : linkController.text.trim(),
                  'ordem_exibicao': int.tryParse(ordemController.text) ?? 0,
                  'ativo': ativo,
                });
                
                if (!mounted) return;
                if (success) {
                  Navigator.of(ctx).pop();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Anunciante adicionado!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Erro ao adicionar anunciante'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditParceiroDialog(
    BuildContext context,
    AdminProvider provider,
    int id,
    String imagemUrl,
    String? linkUrl,
    int ordem,
    bool ativo,
  ) {
    final imagemController = TextEditingController(text: imagemUrl);
    final linkController = TextEditingController(text: linkUrl ?? '');
    final ordemController = TextEditingController(text: ordem.toString());
    bool ativoLocal = ativo;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Anunciante'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: imagemController,
                  decoration: const InputDecoration(
                    labelText: 'URL da Imagem *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(
                    labelText: 'URL do Link (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ordemController,
                  decoration: const InputDecoration(
                    labelText: 'Ordem de Exibição',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Ativo'),
                  value: ativoLocal,
                  onChanged: (value) {
                    setState(() {
                      ativoLocal = value ?? true;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (imagemController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('URL da imagem é obrigatória')),
                  );
                  return;
                }
                
                final success = await provider.updateParceiro(id, {
                  'imagem_url': imagemController.text.trim(),
                  'link_url': linkController.text.trim().isEmpty ? null : linkController.text.trim(),
                  'ordem_exibicao': int.tryParse(ordemController.text) ?? ordem,
                  'ativo': ativoLocal,
                });
                
                if (!mounted) return;
                if (success) {
                  Navigator.of(ctx).pop();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Anunciante atualizado!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Erro ao atualizar anunciante'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarExclusaoParceiro(BuildContext context, AdminProvider provider, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir este anunciante?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    
    if (!mounted) return;
    if (confirm == true) {
      final success = await provider.deleteParceiro(id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anunciante excluído!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Erro ao excluir anunciante'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMarketplaceTab() {
    return Consumer<MarketplaceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.itensAdmin.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: null,
                      decoration: const InputDecoration(
                        labelText: 'Filtrar por status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todos')),
                        DropdownMenuItem(value: 'PENDENTE', child: Text('Pendente')),
                        DropdownMenuItem(value: 'APROVADO', child: Text('Aprovado')),
                        DropdownMenuItem(value: 'REJEITADO', child: Text('Rejeitado')),
                      ],
                      onChanged: (value) {
                        provider.loadItensAdmin(status: value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => provider.loadItensAdmin(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.itensAdmin.isEmpty
                  ? const Center(child: Text('Nenhum item encontrado.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.itensAdmin.length,
                      itemBuilder: (context, index) {
                        final item = provider.itensAdmin[index];
                        return _buildMarketplaceItemCard(context, item, provider);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMarketplaceItemCard(BuildContext context, MarketplaceItem item, MarketplaceProvider provider) {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final baseUrl = apiClient.baseUrl;

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
                    item.titulo,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.status == 'APROVADO'
                        ? Colors.green.shade100
                        : item.status == 'REJEITADO'
                            ? Colors.red.shade100
                            : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.statusLabel,
                    style: TextStyle(
                      color: item.status == 'APROVADO'
                          ? Colors.green.shade700
                          : item.status == 'REJEITADO'
                              ? Colors.red.shade700
                              : Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (item.fotos.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  '$baseUrl${item.fotos[0]}',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 64),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text('Tipo: ${item.tipoLabel}'),
            Text('Valor: R\$ ${item.valor.toStringAsFixed(2)}'),
            if (item.policialNome != null) Text('Vendedor: ${item.policialNome}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (item.status == 'PENDENTE') ...[
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      final success = await provider.aprovarItem(item.id);
                      if (!mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Item aprovado!')),
                        );
                        provider.loadItensAdmin();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      final success = await provider.rejeitarItem(item.id);
                      if (!mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Item rejeitado.')),
                        );
                        provider.loadItensAdmin();
                      }
                    },
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirmar exclusão'),
                        content: const Text('Deseja realmente excluir este item?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Excluir'),
                          ),
                        ],
                      ),
                    );
                    if (!mounted) return;
                    if (confirm == true) {
                      final success = await provider.deleteItemAdmin(item.id);
                      if (!mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Item excluído!')),
                        );
                        provider.loadItensAdmin();
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}