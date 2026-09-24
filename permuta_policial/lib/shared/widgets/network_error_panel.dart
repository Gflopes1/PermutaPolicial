import 'package:flutter/material.dart';
import '../../core/api/api_exception.dart';

/// Painel de erro de rede com mensagem específica e botão retry.
class NetworkErrorPanel extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final EdgeInsets padding;

  const NetworkErrorPanel({
    super.key,
    required this.error,
    required this.onRetry,
    this.padding = const EdgeInsets.all(24),
  });

  static String messageFor(Object error) {
    if (error is ApiException) return error.message;
    final text = error.toString().toLowerCase();
    if (text.contains('timeout')) {
      return 'A requisição demorou muito. Verifique sua conexão e tente novamente.';
    }
    if (text.contains('socket') || text.contains('failed host lookup')) {
      return 'Sem conexão com a internet. Verifique sua rede.';
    }
    return 'Não foi possível carregar os dados. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: 'Erro de conexão',
            child: const Icon(Icons.cloud_off, size: 48, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          Text(
            messageFor(error),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Semantics(
            button: true,
            label: 'Tentar novamente',
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }
}
