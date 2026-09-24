// Envio de push notifications via FCM HTTP v1

const pushRepository = require('./push.repository');
const fcmV1 = require('./fcm-v1.client');
const logger = require('../../core/utils/logger');

async function sendPushToUser(policialId, { title, body, data = {} }) {
  const tipo = data.tipo || '?';
  logger.log(`[push] sendPushToUser policial=${policialId} tipo=${tipo}`);

  if (!fcmV1.isFcmConfigured()) {
    console.warn(
      `[push] FCM v1 NÃO configurado — push ignorado (policial=${policialId}, tipo=${tipo}). ` +
        'Defina FCM_SERVICE_ACCOUNT_JSON e FCM_PROJECT_ID no servidor.'
    );
    return {
      sent: 0,
      skipped: 'FCM v1 não configurado (service account + FCM_PROJECT_ID)',
    };
  }

  const tokens = await pushRepository.findTokensByPolicialId(policialId);
  if (!tokens.length) {
    console.warn(
      `[push] sem_tokens policial=${policialId} tipo=${tipo} — destinatário não registrou push neste dispositivo`
    );
    return { sent: 0, skipped: 'sem_tokens' };
  }

  logger.log(`[push] enviando para ${tokens.length} token(s) policial=${policialId} tipo=${tipo}`);
  let sent = 0;
  let pruned = 0;

  for (const row of tokens) {
    const result = await fcmV1.sendToToken(row.token, row.platform || 'android', {
      title,
      body,
      data,
    });

    if (result.ok) {
      sent += 1;
      logger.log(`[push] OK policial=${policialId} platform=${row.platform || 'android'}`);
      continue;
    }

    if (fcmV1.isInvalidTokenError(result.errorCode, result.status)) {
      const removed = await pushRepository.deleteTokenByValue(row.token);
      if (removed) pruned += 1;
      console.warn(
        `[push] Token inválido removido (policial ${policialId}, ${result.errorCode}): ${result.errorMessage}`
      );
      continue;
    }

    console.error(
      `[push] Falha FCM v1 para policial ${policialId}:`,
      result.errorCode,
      result.errorMessage
    );
  }

  if (sent === 0) {
    console.warn(
      `[push] falha_total policial=${policialId} tipo=${tipo} tokens=${tokens.length} pruned=${pruned}`
    );
  } else {
    logger.log(`[push] concluído policial=${policialId} tipo=${tipo} sent=${sent}/${tokens.length}`);
  }

  return { sent, pruned, tokens: tokens.length };
}
module.exports = { sendPushToUser };
