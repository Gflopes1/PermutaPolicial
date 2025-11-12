// /lib/features/admin/widgets/parceiros_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/admin_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../core/models/parceiro.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../core/api/api_exception.dart';

class ParceirosTab extends StatelessWidget {
  final AdminProvider provider;

  const ParceirosTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.parceiros.isEmpty) {
          return const LoadingWidget();
        }

        return Column(
          children: [
            // Configuração
            Card(
              margin: const EdgeInsets.all(AppConstants.spacingMD),
              child: SwitchListTile(
                title: const Text('Exibir Card de Parceiros'),
                subtitle: const Text('Mostrar o card de parceiros no dashboard'),
                value: provider.exibirCardParceiros,
                onChanged: (value) async {
                  try {
                    await provider.updateParceirosConfig(value);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Configuração atualizada'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            // Lista de parceiros
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.loadParceiros(),
                child: provider.parceiros.isEmpty
                    ? const Center(child: Text('Nenhum parceiro cadastrado'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingMD,
                        ),
                        itemCount: provider.parceiros.length,
                        itemBuilder: (context, index) {
                          final parceiro = provider.parceiros[index];
                          return _buildParceiroCard(context, parceiro);
                        },
                      ),
              ),
            ),
            // Botão adicionar
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMD),
              child: ElevatedButton.icon(
                onPressed: () => _showAddParceiroDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Parceiro'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildParceiroCard(BuildContext context, Parceiro parceiro) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSM),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppConstants.spacingMD),
        leading: CircleAvatar(
          backgroundColor: parceiro.ativo ? Colors.green : Colors.grey,
          child: Icon(
            parceiro.ativo ? Icons.check : Icons.close,
            color: Colors.white,
          ),
        ),
        title: Text(
          parceiro.linkUrl ?? 'Sem link',
          style: TextStyle(
            decoration: parceiro.linkUrl != null
                ? TextDecoration.underline
                : TextDecoration.none,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('URL da Imagem: ${parceiro.imagemUrl}'),
            Text('Ordem: ${parceiro.ordem}'),
            Text('Status: ${parceiro.ativo ? "Ativo" : "Inativo"}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditParceiroDialog(context, parceiro),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmDialog(context, parceiro),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddParceiroDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final imagemUrlController = TextEditingController();
    final linkUrlController = TextEditingController();
    final ordemController = TextEditingController(text: '0');
    bool ativo = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adicionar Parceiro'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: imagemUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL da Imagem *',
                      hintText: 'https://exemplo.com/imagem.png',
                    ),
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'URL da imagem é obrigatória' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: linkUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL do Link (opcional)',
                      hintText: 'https://exemplo.com',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ordemController,
                    decoration: const InputDecoration(
                      labelText: 'Ordem',
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Ativo'),
                    value: ativo,
                    onChanged: (value) => setState(() => ativo = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await provider.createParceiro(
                      Parceiro(
                        id: 0,
                        imagemUrl: imagemUrlController.text.trim(),
                        linkUrl: linkUrlController.text.trim().isEmpty
                            ? null
                            : linkUrlController.text.trim(),
                        ordem: int.tryParse(ordemController.text) ?? 0,
                        ativo: ativo,
                      ),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Parceiro adicionado com sucesso'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } on ApiException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ErrorMessageHelper.getFriendlyMessage(e),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditParceiroDialog(BuildContext context, Parceiro parceiro) {
    final formKey = GlobalKey<FormState>();
    final imagemUrlController = TextEditingController(text: parceiro.imagemUrl);
    final linkUrlController = TextEditingController(text: parceiro.linkUrl ?? '');
    final ordemController = TextEditingController(text: parceiro.ordem.toString());
    bool ativo = parceiro.ativo;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Parceiro'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: imagemUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL da Imagem *',
                    ),
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'URL da imagem é obrigatória' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: linkUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL do Link (opcional)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ordemController,
                    decoration: const InputDecoration(
                      labelText: 'Ordem',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Ativo'),
                    value: ativo,
                    onChanged: (value) => setState(() => ativo = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await provider.updateParceiro(
                      parceiro.id,
                      Parceiro(
                        id: parceiro.id,
                        imagemUrl: imagemUrlController.text.trim(),
                        linkUrl: linkUrlController.text.trim().isEmpty
                            ? null
                            : linkUrlController.text.trim(),
                        ordem: int.tryParse(ordemController.text) ?? 0,
                        ativo: ativo,
                      ),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Parceiro atualizado com sucesso'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } on ApiException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ErrorMessageHelper.getFriendlyMessage(e),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Parceiro parceiro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja remover este parceiro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.deleteParceiro(parceiro.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Parceiro removido com sucesso'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

