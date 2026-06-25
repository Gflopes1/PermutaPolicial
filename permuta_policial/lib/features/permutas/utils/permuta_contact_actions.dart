import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_styles.dart';
import '../../../core/models/match_results.dart';
import '../../../core/utils/phone_copy_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/providers/chat_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../notificacoes/providers/notificacoes_provider.dart';

/// Ações compartilhadas de contato/mensagem nos resultados de permuta.
class PermutaContactActions {
  PermutaContactActions._();

  static Future<bool> solicitarContato(
    BuildContext context, {
    required int destinatarioId,
    required String tipoPermuta,
    VoidCallback? onSuccess,
  }) async {
    final notificacoesProvider =
        Provider.of<NotificacoesProvider>(context, listen: false);

    try {
      final success = await notificacoesProvider.criarSolicitacaoContato(
        destinatarioId,
        origem: 'permuta',
        tipoPermuta: tipoPermuta,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          success
              ? (notificacoesProvider.isDuplicate
                  ? AppStyles.successSnackBar('Contato já solicitado.')
                  : AppStyles.successSnackBar(
                      'Solicitação de contato enviada com sucesso!',
                    ))
              : AppStyles.errorSnackBar('Erro ao enviar solicitação de contato.'),
        );
        if (success) onSuccess?.call();
      }
      return success;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.errorSnackBar('Erro ao enviar solicitação: $e'),
        );
      }
      return false;
    }
  }

  /// Mensagem para match: se o destinatário tem privacidade, conversa anônima
  /// (oculta o destinatário para quem envia; remetente visível), como no mapa.
  static Future<void> enviarMensagemParaMatch(
    BuildContext context,
    Match match,
  ) {
    if (match.id <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.errorSnackBar(
            'Não foi possível identificar o destinatário. Atualize os resultados e tente novamente.',
          ),
        );
      }
      return Future.value();
    }
    final destinatarioComPrivacidade =
        match.ocultarNoMapa && !match.aceitouCompartilhar;
    return enviarMensagem(
      context,
      destinatarioId: match.id,
      isAnonima: destinatarioComPrivacidade,
    );
  }

  static int? _currentUserId(BuildContext context) {
    return context.read<AuthProvider>().user?.id ??
        context.read<DashboardProvider>().userData?.id;
  }

  /// Inicia conversa com outro policial.
  /// [isAnonima]: destinatário com privacidade ativa (remetente continua identificado).
  static Future<void> enviarMensagem(
    BuildContext context, {
    required int destinatarioId,
    bool isAnonima = false,
  }) async {
    if (destinatarioId <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.errorSnackBar('Destinatário inválido.'),
        );
      }
      return;
    }

    final meuId = _currentUserId(context);
    if (meuId != null && meuId == destinatarioId) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.errorSnackBar('Você não pode enviar mensagem para si mesmo.'),
        );
      }
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    try {
      await chatProvider.initializeSocket();
      final conversa =
          await chatProvider.iniciarConversa(destinatarioId, anonima: isAnonima);

      if (conversa != null && context.mounted) {
        final nome = conversa['anonima'] &&
                !conversa['remetente_revelado'] &&
                conversa['iniciada_por'] == destinatarioId
            ? 'Usuário não identificado'
            : (conversa['outro_usuario_nome'] ?? 'Usuário');
        context.push(
          '/chat/conversa/${conversa['id']}?nome=${Uri.encodeComponent(nome)}',
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.errorSnackBar(
            chatProvider.errorMessage ?? 'Erro ao iniciar conversa.',
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.errorSnackBar('Erro ao enviar mensagem: $e'),
        );
      }
    }
  }

  static void showQsoDialog(BuildContext context, Match match) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final hasQso = match.qso != null && match.qso!.isNotEmpty;
        return AlertDialog(
          title: Text(match.nome),
          content: hasQso
              ? SelectableText(match.qso!, style: const TextStyle(fontSize: 16))
              : const Text('Este usuário não informou um número de contato.'),
          actions: [
            if (hasQso)
              TextButton(
                onPressed: () {
                  copiarTelefoneComAnalytics(
                    context,
                    telefone: match.qso!,
                    origem: 'permuta',
                    policialId: match.id,
                  );
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Copiar Número'),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}
