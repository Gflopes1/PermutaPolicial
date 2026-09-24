import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/app_share.dart';
import '../providers/referral_provider.dart';

class ReferralShareButtons extends StatelessWidget {
  final String link;
  final String code;
  final VoidCallback? onShared;

  const ReferralShareButtons({
    super.key,
    required this.link,
    required this.code,
    this.onShared,
  });

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copiado!')),
      );
    }
  }

  Future<void> _share(BuildContext context) async {
    final text = ReferralProvider.whatsAppMessage(link);
    final shared = await shareText(text, subject: 'Permuta Policial');
    onShared?.call();
    if (!shared && context.mounted) {
      await _copyLink(context);
    }
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    final text = ReferralProvider.whatsAppMessage(link);
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
    } else {
      onShared?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => _shareWhatsApp(context),
          icon: const Icon(Icons.chat),
          label: const Text('Compartilhar no WhatsApp'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _share(context),
          icon: const Icon(Icons.share),
          label: const Text('Compartilhar'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _copyLink(context),
          icon: const Icon(Icons.link),
          label: const Text('Copiar link'),
        ),
      ],
    );
  }
}
