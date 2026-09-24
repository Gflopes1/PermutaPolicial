// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_styles.dart';
import '../../../core/models/consultoria_advogado.dart';
import '../../admin/providers/admin_provider.dart';
import '../../consultoria_juridica/utils/consultoria_photo_url.dart';

class ConsultoriaJuridicaAdminTab extends StatefulWidget {
  const ConsultoriaJuridicaAdminTab({super.key});

  @override
  State<ConsultoriaJuridicaAdminTab> createState() => _ConsultoriaJuridicaAdminTabState();
}

class _ConsultoriaJuridicaAdminTabState extends State<ConsultoriaJuridicaAdminTab> {
  bool _statsExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProvider>();
      provider.loadConsultoriaAdvogados();
      provider.loadConsultoriaClickStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.consultoriaAdvogados.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadConsultoriaAdvogados();
            await provider.loadConsultoriaClickStats();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FilledButton.icon(
                onPressed: provider.isLoading ? null : () => _showFormDialog(context, provider),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar profissional'),
              ),
              const SizedBox(height: 12),
              _buildStatsCard(provider),
              const SizedBox(height: 16),
              if (provider.consultoriaAdvogados.isEmpty)
                const Center(child: Text('Nenhum profissional cadastrado.'))
              else
                ...provider.consultoriaAdvogados.map((a) => _buildItem(context, provider, a)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(AdminProvider provider) {
    final stats = provider.consultoriaClickStats;
    final byUser = provider.consultoriaClicksByUser;

    return Card(
      child: ExpansionTile(
        initiallyExpanded: _statsExpanded,
        onExpansionChanged: (v) => setState(() => _statsExpanded = v),
        title: const Text('Estatísticas de cliques'),
        subtitle: Text('${stats.length} profissionais rastreados'),
        children: [
          if (stats.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nenhum clique registrado ainda.'),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: stats.map((s) {
                  return ListTile(
                    dense: true,
                    title: Text(s.advogadoNome),
                    subtitle: Text(
                      'Contato: ${s.cliquesContato} • Site: ${s.cliquesSite} • Total: ${s.cliquesTotal}',
                    ),
                  );
                }).toList(),
              ),
            ),
            if (byUser.isNotEmpty) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Quem clicou', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              ...byUser.take(50).map((u) {
                final quem = u.usuarioNome?.isNotEmpty == true
                    ? u.usuarioNome!
                    : (u.usuarioEmail ?? 'Usuário #${u.usuarioId ?? "?"}');
                return ListTile(
                  dense: true,
                  title: Text(quem),
                  subtitle: Text(
                    '${u.advogadoNome} • ${u.tipoClique == "site" ? "Site" : "Contato"} • ${u.total}x',
                  ),
                );
              }),
            ],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, AdminProvider provider, ConsultoriaAdvogado adv) {
    final photo = resolveConsultoriaPhotoUrl(adv.fotoUrl);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: SizedBox(
          width: 48,
          height: 72,
          child: photo.isEmpty
              ? const Icon(Icons.person)
              : Image.network(photo, fit: BoxFit.cover),
        ),
        title: Text(adv.nome),
        subtitle: Text(
          '${adv.descricaoCurta}\nOrdem: ${adv.ordem} • ${adv.ativo ? "Ativo" : "Inativo"}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              _showFormDialog(context, provider, existing: adv);
            } else if (value == 'delete') {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Excluir profissional'),
                  content: Text('Excluir "${adv.nome}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
                  ],
                ),
              );
              if (ok != true) return;
              final success = await provider.deleteConsultoriaAdvogado(adv.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                success
                    ? AppStyles.successSnackBar('Profissional excluído.')
                    : AppStyles.errorSnackBar(provider.errorMessage ?? 'Erro ao excluir.'),
              );
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }

  Future<void> _showFormDialog(
    BuildContext context,
    AdminProvider provider, {
    ConsultoriaAdvogado? existing,
  }) async {
    final nomeController = TextEditingController(text: existing?.nome ?? '');
    final curtaController = TextEditingController(text: existing?.descricaoCurta ?? '');
    final detalhadaController = TextEditingController(text: existing?.descricaoDetalhada ?? '');
    final siteController = TextEditingController(text: existing?.siteUrl ?? '');
    final whatsappController = TextEditingController(text: existing?.contatoWhatsapp ?? '');
    final telefoneController = TextEditingController(text: existing?.contatoTelefone ?? '');
    final emailController = TextEditingController(text: existing?.contatoEmail ?? '');
    final ordemController = TextEditingController(text: '${existing?.ordem ?? 0}');

    Uint8List? photoBytes;
    String? photoName;
    bool ativo = existing?.ativo ?? true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(existing == null ? 'Novo profissional' : 'Editar profissional'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1600,
                          imageQuality: 85,
                        );
                        if (file == null) return;
                        final bytes = await file.readAsBytes();
                        setDialogState(() {
                          photoBytes = bytes;
                          photoName = file.name;
                        });
                      },
                      icon: const Icon(Icons.photo),
                      label: Text(photoBytes != null ? 'Foto selecionada' : 'Selecionar foto *'),
                    ),
                    if (existing != null && photoBytes == null && existing.fotoUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Foto atual mantida se nenhuma nova for enviada.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(labelText: 'Nome / Escritório *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: curtaController,
                      decoration: const InputDecoration(
                        labelText: 'Área de atuação (breve) *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: detalhadaController,
                      decoration: const InputDecoration(
                        labelText: 'Detalhes (tela de detalhe)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: siteController,
                      decoration: const InputDecoration(labelText: 'Site', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: whatsappController,
                      decoration: const InputDecoration(labelText: 'WhatsApp', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: telefoneController,
                      decoration: const InputDecoration(labelText: 'Telefone', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ordemController,
                      decoration: const InputDecoration(labelText: 'Ordem', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ativo'),
                      value: ativo,
                      onChanged: (v) => setDialogState(() => ativo = v ?? true),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () async {
                  if (nomeController.text.trim().isEmpty || curtaController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nome e descrição curta são obrigatórios.')),
                    );
                    return;
                  }
                  if (existing == null && photoBytes == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selecione uma foto.')),
                    );
                    return;
                  }

                  final fields = {
                    'nome': nomeController.text.trim(),
                    'descricao_curta': curtaController.text.trim(),
                    'descricao_detalhada': detalhadaController.text.trim(),
                    'site_url': siteController.text.trim(),
                    'contato_whatsapp': whatsappController.text.trim(),
                    'contato_telefone': telefoneController.text.trim(),
                    'contato_email': emailController.text.trim(),
                    'ordem': '${int.tryParse(ordemController.text) ?? 0}',
                    'ativo': ativo.toString(),
                  };

                  final success = existing == null
                      ? await provider.createConsultoriaAdvogado(
                          fields: fields,
                          photoBytes: photoBytes!,
                          photoFilename: photoName,
                        )
                      : await provider.updateConsultoriaAdvogado(
                          id: existing.id,
                          fields: fields,
                          photoBytes: photoBytes,
                          photoFilename: photoName,
                        );

                  if (!context.mounted) return;
                  if (success) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      AppStyles.successSnackBar(existing == null ? 'Profissional criado.' : 'Profissional atualizado.'),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      AppStyles.errorSnackBar(provider.errorMessage ?? 'Erro ao salvar.'),
                    );
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }
}
