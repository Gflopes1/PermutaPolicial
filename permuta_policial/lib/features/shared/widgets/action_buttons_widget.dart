// /lib/features/shared/widgets/action_buttons_widget.dart

import 'package:flutter/material.dart';

/// Widget que exibe botões de ação (Solicitar Contato e Enviar Mensagem)
/// com layout adaptativo: horizontal no desktop, vertical no mobile
class ActionButtonsWidget extends StatelessWidget {
  final VoidCallback onSolicitarContato;
  final VoidCallback onEnviarMensagem;
  final bool isAnonima;
  final Color? solicitarContatoColor;
  final Color? solicitarContatoForegroundColor;
  final bool fullWidth;

  const ActionButtonsWidget({
    super.key,
    required this.onSolicitarContato,
    required this.onEnviarMensagem,
    this.isAnonima = false,
    this.solicitarContatoColor,
    this.solicitarContatoForegroundColor,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    
    // Se fullWidth é true (para usuários ocultos), sempre usa vertical no mobile
    if (!isDesktop || fullWidth) {
      return _buildVerticalLayout(context);
    }
    
    return _buildHorizontalLayout(context);
  }

  Widget _buildVerticalLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onSolicitarContato,
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Solicitar Contato'),
            style: ElevatedButton.styleFrom(
              backgroundColor: solicitarContatoColor ?? Theme.of(context).colorScheme.primary,
              foregroundColor: solicitarContatoForegroundColor ?? Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onEnviarMensagem,
            icon: const Icon(Icons.message, size: 18),
            label: const Text('Enviar Mensagem'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onSolicitarContato,
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Solicitar Contato'),
            style: ElevatedButton.styleFrom(
              backgroundColor: solicitarContatoColor ?? Theme.of(context).colorScheme.primary,
              foregroundColor: solicitarContatoForegroundColor ?? Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEnviarMensagem,
            icon: const Icon(Icons.message, size: 18),
            label: const Text('Enviar Mensagem'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

