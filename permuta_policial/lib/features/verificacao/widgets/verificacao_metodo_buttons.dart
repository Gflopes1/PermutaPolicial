import 'package:flutter/material.dart';

class BetaBadge extends StatelessWidget {
  /// Use [onDarkBackground: true] sobre botões coloridos (ex.: ElevatedButton).
  final bool onDarkBackground;

  const BetaBadge({super.key, this.onDarkBackground = false});

  @override
  Widget build(BuildContext context) {
    const betaBg = Color(0xFFFFB300);
    const betaFg = Color(0xFF3E2723);

    final bg = onDarkBackground ? betaBg : const Color(0xFFFFF8E1);
    final fg = onDarkBackground ? betaFg : const Color(0xFF5D4037);
    final border = onDarkBackground ? const Color(0xFF6D4C41) : const Color(0xFFFF8F00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Text(
        'BETA',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: fg,
              height: 1.1,
            ),
      ),
    );
  }
}

class VerificacaoWhatsappButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;

  const VerificacaoWhatsappButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : const Icon(Icons.chat_outlined),
        label: Text(loading ? 'Abrindo WhatsApp...' : 'Verificação via WhatsApp'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFF128C7E),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class VerificacaoDocumentoButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool showBeta;

  const VerificacaoDocumentoButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.showBeta = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.document_scanner_outlined, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
              ),
            ),
            if (showBeta) ...[
              const SizedBox(width: 8),
              const BetaBadge(onDarkBackground: true),
            ],
          ],
        ),
      ),
    );
  }
}
