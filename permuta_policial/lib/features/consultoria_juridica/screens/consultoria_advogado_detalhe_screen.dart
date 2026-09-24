import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/repositories/consultoria_juridica_repository.dart';
import '../../../core/config/app_styles.dart';
import '../../../core/models/consultoria_advogado.dart';
import '../utils/consultoria_photo_url.dart';

class ConsultoriaAdvogadoDetalheScreen extends StatefulWidget {
  final int advogadoId;

  const ConsultoriaAdvogadoDetalheScreen({super.key, required this.advogadoId});

  @override
  State<ConsultoriaAdvogadoDetalheScreen> createState() => _ConsultoriaAdvogadoDetalheScreenState();
}

class _ConsultoriaAdvogadoDetalheScreenState extends State<ConsultoriaAdvogadoDetalheScreen> {
  ConsultoriaAdvogado? _advogado;
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
      final repo = context.read<ConsultoriaJuridicaRepository>();
      final adv = await repo.getPublicById(widget.advogadoId);
      if (!mounted) return;
      setState(() {
        _advogado = adv;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar os dados.';
        _loading = false;
      });
    }
  }

  Future<void> _onContato() async {
    final adv = _advogado;
    if (adv == null || !adv.hasContato) return;

    final repo = context.read<ConsultoriaJuridicaRepository>();
    await repo.registerClick(adv.id, 'contato');

    if (adv.contatoWhatsapp?.isNotEmpty == true) {
      final digits = adv.contatoWhatsapp!.replaceAll(RegExp(r'\D'), '');
      final uri = Uri.parse('https://wa.me/$digits');
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    }
    if (adv.contatoTelefone?.isNotEmpty == true) {
      final uri = Uri.parse('tel:${adv.contatoTelefone}');
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    }
    if (adv.contatoEmail?.isNotEmpty == true) {
      final uri = Uri.parse('mailto:${adv.contatoEmail}');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _onSite() async {
    final adv = _advogado;
    if (adv == null || !adv.hasSite) return;

    var url = adv.siteUrl!.trim();
    if (!url.startsWith('http')) url = 'https://$url';

    final repo = context.read<ConsultoriaJuridicaRepository>();
    await repo.registerClick(adv.id, 'site');

    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppStyles.errorSnackBar('Não foi possível abrir o site.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adv = _advogado;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(adv?.nome ?? 'Consultoria Jurídica')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('Tentar novamente')),
                    ],
                  ),
                )
              : adv == null
                  ? const Center(child: Text('Profissional não encontrado.'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    width: 96,
                                    height: 96,
                                    child: _buildPhoto(adv),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  adv.nome,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  adv.descricaoCurta,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (adv.descricaoDetalhada?.isNotEmpty == true) ...[
                                  Text(
                                    'Sobre',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(adv.descricaoDetalhada!),
                                  const SizedBox(height: 24),
                                ],
                                if (adv.hasContato)
                                  FilledButton.icon(
                                    onPressed: _onContato,
                                    icon: const Icon(Icons.contact_phone),
                                    label: const Text('Entrar em contato'),
                                  ),
                                if (adv.hasContato && adv.hasSite) const SizedBox(height: 10),
                                if (adv.hasSite)
                                  OutlinedButton.icon(
                                    onPressed: _onSite,
                                    icon: const Icon(Icons.language),
                                    label: const Text('Visitar site'),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildPhoto(ConsultoriaAdvogado adv) {
    final url = resolveConsultoriaPhotoUrl(adv.fotoUrl);
    if (url.isEmpty) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.gavel, size: 40)),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.broken_image, size: 40)),
      ),
    );
  }
}
