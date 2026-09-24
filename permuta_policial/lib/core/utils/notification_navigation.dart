import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/app_router.dart';
import '../models/notificacao.dart';
import '../../features/chat/providers/chat_provider.dart';
import '../api/repositories/chat_repository.dart';

/// Rota de destino quando basta [tipo] + [referenciaId] (push / deep link simples).
String? staticRouteForNotificacaoTipo(String tipo, int? referenciaId) {
  switch (tipo) {
    case 'NOVA_MENSAGEM':
      if (referenciaId != null) return '/chat/conversa/$referenciaId';
      return '/dashboard';
    case 'NOVO_MATCH':
      return '/permutas';
    case 'SOLICITACAO_CONTATO':
    case 'SOLICITACAO_CONTATO_NEGADA':
      return '/notificacoes';
    case 'MAPA_TATICO_CONVITE':
      return '/mapa-tatico';
    case 'MAPA_TATICO_PONTO':
    case 'MAPA_TATICO_COMENTARIO':
    case 'MAPA_TATICO_DENUNCIA':
    case 'MAPA_TATICO_PROXIMIDADE':
      if (referenciaId != null) return '/mapa-tatico/ponto/$referenciaId';
      return '/mapa-tatico';
    default:
      return null;
  }
}

/// Navegação a partir de push FCM (sem BuildContext assíncrono).
void navigateForPushTipo(String tipo, String? referenciaId) async {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) return;

  if (tipo == 'SOLICITACAO_CONTATO_ACEITA') {
    await _openChatWithUser(ctx, int.tryParse(referenciaId ?? ''));
    return;
  }

  if (tipo == 'NOVA_MENSAGEM' && referenciaId != null) {
    await _openChatByConversaId(ctx, int.tryParse(referenciaId));
    return;
  }

  final route = staticRouteForNotificacaoTipo(
    tipo,
    int.tryParse(referenciaId ?? ''),
  );
  if (route != null) ctx.go(route);
}

Future<void> _openChatByConversaId(BuildContext context, int? conversaId) async {
  if (conversaId == null || !context.mounted) return;

  try {
    final conversa = await context.read<ChatRepository>().getConversa(conversaId);
    if (!context.mounted) return;
    final nome = conversa['outro_usuario_nome'] as String? ?? 'Usuário';
    context.push(
      '/chat/conversa/$conversaId?nome=${Uri.encodeComponent(nome)}',
    );
  } catch (_) {
    if (context.mounted) {
      context.push('/chat/conversa/$conversaId');
    }
  }
}

/// Navegação a partir da lista in-app de notificações.
Future<void> navigateFromNotificacao(BuildContext context, Notificacao n) async {
  if (n.tipo == 'SOLICITACAO_CONTATO_ACEITA' && n.referenciaId != null) {
    await _openChatWithUser(context, n.referenciaId, displayName: n.aceitadorNome);
    return;
  }

  if (n.tipo == 'NOVA_MENSAGEM' && n.referenciaId != null) {
    await _openChatByConversaId(context, n.referenciaId);
    return;
  }

  final route = staticRouteForNotificacaoTipo(n.tipo, n.referenciaId);
  if (route != null && context.mounted) {
    context.push(route);
  }
}

Future<void> _openChatWithUser(
  BuildContext context,
  int? userId, {
  String? displayName,
}) async {
  if (userId == null || !context.mounted) return;

  final chatProvider = context.read<ChatProvider>();
  await chatProvider.initializeSocket();
  final conversa = await chatProvider.iniciarConversa(userId);

  if (!context.mounted || conversa == null) return;

  final nome = displayName ??
      conversa['outro_usuario_nome'] as String? ??
      'Usuário';
  context.push(
    '/chat/conversa/${conversa['id']}?nome=${Uri.encodeComponent(nome)}',
  );
}
