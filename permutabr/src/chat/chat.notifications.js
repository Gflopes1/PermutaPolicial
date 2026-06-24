// Notificação in-app + push FCM para novas mensagens de chat.

const db = require('../../config/db');
const chatRepository = require('./chat.repository');
const notificacoesRepository = require('../notificacoes/notificacoes.repository');
const { sendPushToUser } = require('../push/push.sender');
const logger = require('../../core/utils/logger');

async function getPolicialNome(policialId) {
  const [rows] = await db.execute('SELECT nome FROM policiais WHERE id = ?', [policialId]);
  return rows[0]?.nome || 'Usuário';
}

/**
 * Cria notificação in-app e envia push FCM ao destinatário da conversa.
 * @returns {{ outroUsuarioId: number, titulo: string, mensagem: string, pushResult: object } | null}
 */
async function notifyNewChatMessage(conversaId, remetenteId) {
  logger.log(`[chat] notifyNewChatMessage conversa=${conversaId} remetente=${remetenteId}`);

  const conversa = await chatRepository.findConversaById(conversaId);
  if (!conversa) {
    console.warn(`[chat] conversa ${conversaId} não encontrada — push ignorado`);
    return null;
  }

  const outroUsuarioId =
    conversa.usuario1_id === remetenteId
      ? conversa.usuario2_id
      : conversa.usuario1_id;

  const remetenteNome = await getPolicialNome(remetenteId);
  const nomeParaNotificacao = chatRepository.getParticipantDisplayName(
    conversa,
    remetenteId,
    outroUsuarioId,
    remetenteNome
  );

  const titulo = 'Nova mensagem';
  const mensagem = `${nomeParaNotificacao} enviou uma mensagem`;

  await notificacoesRepository.create({
    usuario_id: outroUsuarioId,
    tipo: 'NOVA_MENSAGEM',
    referencia_id: conversaId,
    titulo,
    mensagem,
  });

  const pushResult = await sendPushToUser(outroUsuarioId, {
    title: titulo,
    body: mensagem,
    data: {
      tipo: 'NOVA_MENSAGEM',
      referencia_id: String(conversaId),
    },
  });

  if (pushResult.sent === 0) {
    console.warn('[chat] Push não entregue', {
      destinatarioId: outroUsuarioId,
      conversaId,
      motivo: pushResult.skipped || 'falha_fcm',
      pruned: pushResult.pruned,
      tokens: pushResult.tokens,
    });
  } else {
    logger.log('[chat] Push enviado', {
      destinatarioId: outroUsuarioId,
      conversaId,
      sent: pushResult.sent,
    });
  }

  return { outroUsuarioId, titulo, mensagem, pushResult };
}

module.exports = { notifyNewChatMessage };
