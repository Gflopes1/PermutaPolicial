import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/user_profile.dart';
import '../../../dashboard/providers/dashboard_provider.dart';
import '../section_card.dart';

class IdentificacaoSection extends StatefulWidget {
  final UserProfile userProfile;

  const IdentificacaoSection({super.key, required this.userProfile});

  @override
  State<IdentificacaoSection> createState() => _IdentificacaoSectionState();
}

class _IdentificacaoSectionState extends State<IdentificacaoSection> {
  late TextEditingController _qsoController;
  late TextEditingController _antiguidadeController;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _qsoController = TextEditingController(text: widget.userProfile.qso ?? '');
    _antiguidadeController = TextEditingController(text: widget.userProfile.antiguidade ?? '');
    _qsoController.addListener(_scheduleAutoSave);
    _antiguidadeController.addListener(_scheduleAutoSave);
  }

  @override
  void didUpdateWidget(covariant IdentificacaoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userProfile.qso != widget.userProfile.qso &&
        _qsoController.text != (widget.userProfile.qso ?? '')) {
      _qsoController.text = widget.userProfile.qso ?? '';
    }
    if (oldWidget.userProfile.antiguidade != widget.userProfile.antiguidade &&
        _antiguidadeController.text != (widget.userProfile.antiguidade ?? '')) {
      _antiguidadeController.text = widget.userProfile.antiguidade ?? '';
    }
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), _autoSave);
  }

  Future<void> _autoSave() async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    final data = <String, dynamic>{};
    if (_qsoController.text != (widget.userProfile.qso ?? '')) {
      data['qso'] = _qsoController.text;
    }
    if (_antiguidadeController.text != (widget.userProfile.antiguidade ?? '')) {
      data['antiguidade'] = _antiguidadeController.text;
    }
    if (data.isNotEmpty) {
      await provider.updateProfile(data);
    }
  }

  Future<void> _openWhatsAppSuporte() async {
    final uri = Uri.parse('https://wa.me/5551986200626');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _qsoController.removeListener(_scheduleAutoSave);
    _antiguidadeController.removeListener(_scheduleAutoSave);
    _qsoController.dispose();
    _antiguidadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      label: 'Identificação',
      children: [
        ProfileReadField(label: 'Nome', value: widget.userProfile.nome, locked: true),
        ProfileReadField(
          label: 'E-mail',
          value: widget.userProfile.email ?? 'Não informado',
          locked: true,
        ),
        ProfileReadField(
          label: 'ID Funcional',
          value: widget.userProfile.idFuncional ?? 'Não informado',
          locked: true,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _qsoController,
          decoration: const InputDecoration(
            labelText: 'QSO (Telefone)',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _antiguidadeController,
          decoration: const InputDecoration(
            labelText: 'Antiguidade',
            prefixIcon: Icon(Icons.calendar_today),
          ),
        ),
        const SizedBox(height: 16),
        _SuporteContatoCard(onPressed: _openWhatsAppSuporte),
      ],
    );
  }
}

class _SuporteContatoCard extends StatelessWidget {
  final VoidCallback onPressed;

  const _SuporteContatoCard({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Para alteração de nome, e-mail, exclusão de conta ou outras solicitações cadastrais, entre em contato conosco via WhatsApp.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue.shade900,
                          height: 1.45,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.chat),
                label: const Text('Contato via WhatsApp'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
