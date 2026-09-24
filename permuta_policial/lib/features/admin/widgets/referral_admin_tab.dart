import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/repositories/referral_repository.dart';

class ReferralAdminTab extends StatefulWidget {
  const ReferralAdminTab({super.key});

  @override
  State<ReferralAdminTab> createState() => _ReferralAdminTabState();
}

class _ReferralAdminTabState extends State<ReferralAdminTab> {
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _campaign;
  List<dynamic> _ranking = [];
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
      final repo = context.read<ReferralRepository>();
      final results = await Future.wait([
        repo.getAdminStats(),
        repo.getAdminRanking(),
        repo.getAdminCampaign(),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _ranking = results[1] as List<dynamic>;
          _campaign = results[2] as Map<String, dynamic>?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _defaultCampaignId() {
    final now = DateTime.now();
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    return 'referral_campaign_${y}_$m';
  }

  Future<void> _showCampaignDialog() async {
    final existing = _campaign;
    final idCtrl = TextEditingController(
      text: existing?['id']?.toString() ?? _defaultCampaignId(),
    );
    final titleCtrl = TextEditingController(
      text: existing?['title']?.toString() ??
          'Convide colegas da sua força',
    );
    final descCtrl = TextEditingController(
      text: existing?['description']?.toString() ??
          'Quanto mais policiais da mesma força na plataforma, maiores as chances de permuta.\n\nCompartilhe seu link com colegas.',
    );
    final primaryLabelCtrl = TextEditingController(
      text: existing?['primary_label']?.toString() ?? 'Convidar colegas',
    );
    final secondaryLabelCtrl = TextEditingController(
      text: existing?['secondary_label']?.toString() ?? 'Agora não',
    );
    var primaryAction = existing?['primary_action']?.toString() ?? 'referral';
    var showShare = existing?['show_share'] != false;
    var active = existing?['active'] != false;
    var saving = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Nova campanha' : 'Editar campanha'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: idCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ID da campanha *',
                      helperText: 'Troque o ID para reexibir a quem já dispensou',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Título *'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Descrição *',
                      helperText: 'Quebras de linha são preservadas no popup',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: primaryAction,
                    decoration: const InputDecoration(labelText: 'Ação principal'),
                    items: const [
                      DropdownMenuItem(value: 'referral', child: Text('Abrir tela Indique colegas')),
                      DropdownMenuItem(value: 'close', child: Text('Apenas fechar')),
                    ],
                    onChanged: (v) => setDialogState(() => primaryAction = v ?? 'referral'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: primaryLabelCtrl,
                    decoration: const InputDecoration(labelText: 'Texto botão principal'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: secondaryLabelCtrl,
                    decoration: const InputDecoration(labelText: 'Texto botão secundário'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mostrar botão compartilhar'),
                    value: showShare,
                    onChanged: (v) => setDialogState(() => showShare = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Campanha ativa'),
                    subtitle: const Text('Desligue para pausar o popup sem apagar'),
                    value: active,
                    onChanged: (v) => setDialogState(() => active = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (idCtrl.text.trim().length < 3 ||
                          titleCtrl.text.trim().isEmpty ||
                          descCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Preencha ID, título e descrição.')),
                        );
                        return;
                      }
                      setDialogState(() => saving = true);
                      try {
                        final repo = context.read<ReferralRepository>();
                        await repo.saveAdminCampaign({
                          'id': idCtrl.text.trim(),
                          'title': titleCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'primary_action': primaryAction,
                          'primary_label': primaryLabelCtrl.text.trim(),
                          'secondary_label': secondaryLabelCtrl.text.trim(),
                          'show_share': showShare,
                          'active': active,
                        });
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Erro ao salvar: $e')),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    idCtrl.dispose();
    titleCtrl.dispose();
    descCtrl.dispose();
    primaryLabelCtrl.dispose();
    secondaryLabelCtrl.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campanha salva com sucesso.')),
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Campanha popup', style: Theme.of(context).textTheme.titleLarge),
              ),
              FilledButton.icon(
                onPressed: _showCampaignDialog,
                icon: const Icon(Icons.campaign_outlined, size: 18),
                label: Text(_campaign == null ? 'Criar' : 'Editar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _campaign == null
                  ? const Text('Nenhuma campanha configurada. Clique em Criar para publicar o popup no dashboard.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _campaign!['title']?.toString() ?? '—',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Chip(
                              label: Text(
                                _campaign!['active'] == false ? 'Pausada' : 'Ativa',
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: _campaign!['active'] == false
                                  ? Colors.orange.shade100
                                  : Colors.green.shade100,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('ID: ${_campaign!['id'] ?? '—'}', style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 8),
                        Text(
                          _campaign!['description']?.toString() ?? '',
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          if (_stats != null) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _statCard('Total', '${_stats!['total_referrals'] ?? 0}'),
                _statCard('Verificados', '${_stats!['verified'] ?? 0}'),
                _statCard('Pendentes', '${_stats!['pending'] ?? 0}'),
                _statCard('Cliques', '${_stats!['clicks'] ?? 0}'),
                _statCard('Cadastros', '${_stats!['signups'] ?? 0}'),
              ],
            ),
            const SizedBox(height: 24),
          ],
          Text('Ranking', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (_ranking.isEmpty)
            const Text('Nenhum indicador ainda.')
          else
            ..._ranking.map((r) {
              final map = r as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(child: Text('${map['rank'] ?? ''}')),
                title: Text(map['public_name']?.toString() ?? '—'),
                subtitle: Text(
                  '${map['forca_sigla'] ?? ''} · ${map['estado_sigla'] ?? ''}',
                ),
                trailing: Text('${map['verified_count'] ?? 0}'),
              );
            }),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
