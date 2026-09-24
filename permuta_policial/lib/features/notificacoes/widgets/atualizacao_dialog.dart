// /lib/features/notificacoes/widgets/atualizacao_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/atualizacao_service.dart';

class AtualizacaoDialog extends StatelessWidget {
  final String nota;
  final String versao;

  const AtualizacaoDialog({
    super.key,
    required this.nota,
    required this.versao,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.update,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Nova Atualização'),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(
          nota,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            // Marca como vista ao fechar
            final atualizacaoService = Provider.of<AtualizacaoService>(context, listen: false);
            await atualizacaoService.marcarComoVista(versao);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Fechar'),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

