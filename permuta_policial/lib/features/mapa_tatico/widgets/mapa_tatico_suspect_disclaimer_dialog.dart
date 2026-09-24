import 'package:flutter/material.dart';

/// Modal de responsabilização exibido antes do primeiro cadastro de suspeito.
Future<bool> showMapaTaticoSuspectDisclaimerDialog(BuildContext context) async {
  var accepted = false;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Responsabilidade pela informação'),
      content: const SingleChildScrollView(
        child: Text(
          'Ao cadastrar um perfil de suspeito, você declara que as informações são '
          'verídicas e de uso operacional restrito ao seu grupo.\n\n'
          'Informações incorretas podem ser contestadas por outros membros e '
          'arquivadas pelos moderadores. Você é responsável pelo conteúdo que publicar.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            accepted = true;
            Navigator.pop(ctx, true);
          },
          child: const Text('Li e aceito'),
        ),
      ],
    ),
  );
  return result == true && accepted;
}
