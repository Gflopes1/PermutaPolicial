import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/repositories/dados_repository.dart';
import '../../../core/api/repositories/editais_repository.dart';
import '../../../core/models/forca_policial.dart';

class EditaisAdminTab extends StatefulWidget {
  const EditaisAdminTab({super.key});

  @override
  State<EditaisAdminTab> createState() => _EditaisAdminTabState();
}

class _EditaisAdminTabState extends State<EditaisAdminTab> {
  List<Map<String, dynamic>> _editais = [];
  List<ForcaPolicial> _forcas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<EditaisRepository>();
      final dadosRepo = context.read<DadosRepository>();
      final editais = await repo.adminListEditais();
      final forcas = await dadosRepo.getForcas();
      if (!mounted) return;
      setState(() {
        _editais = editais;
        _forcas = forcas;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }

  Future<void> _showEditalDialog({Map<String, dynamic>? edital}) async {
    final isEdit = edital != null;
    final tituloCtrl = TextEditingController(text: edital?['titulo']?.toString() ?? '');
    final resumoCtrl = TextEditingController(text: edital?['resumo']?.toString() ?? '');
    final linkCtrl = TextEditingController(text: edital?['link_pdf']?.toString() ?? '');
    final criterioLabelCtrl = TextEditingController(text: edital?['criterio_label']?.toString() ?? 'Classificação');
    String tipo = edital?['tipo']?.toString() ?? 'FORMACAO';
    String status = edital?['status']?.toString() ?? 'RASCUNHO';
    String criterio = edital?['criterio_prioridade']?.toString() ?? 'CLASSIFICACAO_CURSO';
    int? forcaId = edital?['forca_id'] != null ? _asInt(edital!['forca_id']) : null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Editar edital' : 'Novo edital'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: tituloCtrl, decoration: const InputDecoration(labelText: 'Título *')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'FORMACAO', child: Text('Formação')),
                    DropdownMenuItem(value: 'TRANSFERENCIA_INTERNA', child: Text('Transferência interna')),
                  ],
                  onChanged: (v) => setDialogState(() => tipo = v!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: forcaId,
                  decoration: const InputDecoration(labelText: 'Força *'),
                  items: _forcas
                      .map((f) => DropdownMenuItem(value: f.id, child: Text('${f.sigla} - ${f.nome}')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => forcaId = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'RASCUNHO', child: Text('Rascunho')),
                    DropdownMenuItem(value: 'ABERTO', child: Text('Aberto')),
                    DropdownMenuItem(value: 'ENCERRADO', child: Text('Encerrado')),
                  ],
                  onChanged: (v) => setDialogState(() => status = v!),
                ),
                const SizedBox(height: 8),
                TextField(controller: resumoCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Resumo')),
                TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: 'Link PDF')),
                TextField(controller: criterioLabelCtrl, decoration: const InputDecoration(labelText: 'Rótulo do critério')),
                DropdownButtonFormField<String>(
                  initialValue: criterio,
                  decoration: const InputDecoration(labelText: 'Critério prioridade'),
                  items: const [
                    DropdownMenuItem(value: 'CLASSIFICACAO_CURSO', child: Text('Classificação curso')),
                    DropdownMenuItem(value: 'ANTIGUIDADE', child: Text('Antiguidade')),
                    DropdownMenuItem(value: 'PONTUACAO', child: Text('Pontuação')),
                    DropdownMenuItem(value: 'OUTRO', child: Text('Outro')),
                  ],
                  onChanged: (v) => setDialogState(() => criterio = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (tituloCtrl.text.trim().isEmpty || forcaId == null) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final payload = {
      'titulo': tituloCtrl.text.trim(),
      'tipo': tipo,
      'forca_id': forcaId,
      'status': status,
      'resumo': resumoCtrl.text.trim(),
      'link_pdf': linkCtrl.text.trim().isEmpty ? null : linkCtrl.text.trim(),
      'criterio_prioridade': criterio,
      'criterio_label': criterioLabelCtrl.text.trim(),
    };

    final repo = context.read<EditaisRepository>();
    try {
      if (isEdit) {
        await repo.adminUpdateEdital(_asInt(edital['id']), payload);
      } else {
        await repo.adminCreateEdital(payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edital salvo!')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _importCsv(int editalId, String tipo) async {
    final ctrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tipo == 'vagas' ? 'Importar vagas (CSV)' : 'Importar participantes (CSV)'),
        content: TextField(
          controller: ctrl,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'Cole o conteúdo CSV aqui...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Importar')),
        ],
      ),
    );
    if (saved != true || ctrl.text.trim().isEmpty || !mounted) return;

    final repo = context.read<EditaisRepository>();
    try {
      final result = tipo == 'vagas'
          ? await repo.adminImportVagas(editalId, ctrl.text)
          : await repo.adminImportParticipantes(editalId, ctrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Importação concluída: ${result['importados'] ?? 'OK'}')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _deleteEdital(int id, String titulo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir edital'),
        content: Text('Excluir "$titulo"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await context.read<EditaisRepository>().adminDeleteEdital(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edital excluído')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Gestão de Editais', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showEditalDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Novo'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _editais.isEmpty
              ? const Center(child: Text('Nenhum edital cadastrado'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _editais.length,
                  itemBuilder: (context, index) {
                    final e = _editais[index];
                    final id = _asInt(e['id']);
                    final titulo = e['titulo']?.toString() ?? 'Sem título';
                    return Card(
                      child: ListTile(
                        title: Text(titulo),
                        subtitle: Text('${e['forca_sigla'] ?? ''} · ${e['status']} · ${e['tipo']}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            switch (action) {
                              case 'edit':
                                _showEditalDialog(edital: e);
                                break;
                              case 'vagas':
                                _importCsv(id, 'vagas');
                                break;
                              case 'participantes':
                                _importCsv(id, 'participantes');
                                break;
                              case 'delete':
                                _deleteEdital(id, titulo);
                                break;
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Editar')),
                            PopupMenuItem(value: 'vagas', child: Text('Importar vagas')),
                            PopupMenuItem(value: 'participantes', child: Text('Importar participantes')),
                            PopupMenuItem(value: 'delete', child: Text('Excluir')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
