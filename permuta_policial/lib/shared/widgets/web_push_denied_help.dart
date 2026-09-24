import 'package:flutter/material.dart';

import '../../core/utils/pwa_utils.dart';
import '../../core/utils/web_notification_utils.dart';

/// Instruções para reativar notificações quando o navegador bloqueou.
Future<void> showWebPushDeniedHelpDialog(BuildContext context) async {
  final samsung = isSamsungBrowser;
  final ios = isIosWebBrowser;
  final mobile = isMobileWebBrowser;
  final pwa = isPWA();

  String body;
  if (samsung) {
    body =
        'O Samsung Internet costuma bloquear push web ou falhar silenciosamente.\n\n'
        'Recomendado: abra o site no Chrome Android.\n\n'
        'Se quiser continuar no Samsung:\n'
        '1. Toque em ≡ → Configurações → Sites e downloads → Notificações\n'
        '2. Encontre br.permutapolicial.com.br e permita\n'
        '3. Ou: ícone cadeado na barra de endereço → Permissões → Notificações → Permitir\n'
        '4. Feche a aba e abra o site de novo';
  } else if (ios && !pwa) {
    body =
        'No iPhone/iPad, push web só funciona com o app instalado na Tela de Início (iOS 16.4+).\n\n'
        '1. Safari → Compartilhar → Adicionar à Tela de Início\n'
        '2. Abra pelo ícone instalado (não pela aba do Safari)\n'
        '3. Faça login e toque em Ativar notificações';
  } else if (mobile) {
    body =
        'O navegador bloqueou notificações para este site.\n\n'
        '1. Toque no cadeado (ou ⓘ) ao lado do endereço\n'
        '2. Permissões → Notificações → Permitir\n'
        '3. Recarregue a página e toque em Ativar notificações de novo';
  } else {
    body =
        'O navegador bloqueou notificações para br.permutapolicial.com.br.\n\n'
        'Chrome / Edge:\n'
        '1. Clique no cadeado à esquerda da URL\n'
        '2. Notificações → Permitir\n'
        '3. Recarregue (F5) e clique em Ativar notificações\n\n'
        'Ou em chrome://settings/content/notifications remova o site da lista de bloqueados.';
  }

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.notifications_off_outlined, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(child: Text('Notificações bloqueadas')),
        ],
      ),
      content: SingleChildScrollView(child: Text(body)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
}

String webPushBannerHint() {
  if (isSamsungBrowser) {
    return 'Samsung Internet tem suporte limitado. Prefira o Chrome para alertas confiáveis.';
  }
  if (isIosWebBrowser && !isPWA()) {
    return 'No iPhone, instale o app na Tela de Início para receber alertas.';
  }
  return 'Receba avisos de matches e mensagens. Toque em Ativar e escolha Permitir no navegador.';
}
