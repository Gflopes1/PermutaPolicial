const pushRepository = require('./push.repository');
const fcmV1 = require('./fcm-v1.client');
const { sendPushToUser } = require('./push.sender');
const ApiError = require('../../core/utils/ApiError');
const logger = require('../../core/utils/logger');

async function registerDeviceToken(req) {
  const { token, platform = 'android' } = req.body;
  if (!token || token.length < 20) {
    throw new ApiError(400, 'Token de dispositivo inválido.');
  }
  const allowed = ['android', 'ios', 'web'];
  const safePlatform = allowed.includes(platform) ? platform : 'android';
  await pushRepository.upsertToken(req.user.id, token, safePlatform);
  logger.log(`[push] Token registrado policial=${req.user.id} platform=${safePlatform}`);
  return { success: true, message: 'Token registrado.' };
}

async function unregisterDeviceToken(req) {
  const { token } = req.body;
  if (!token) {
    throw new ApiError(400, 'Token é obrigatório.');
  }
  await pushRepository.deleteToken(req.user.id, token);
  return { success: true, message: 'Token removido.' };
}

async function getPushStatus(req) {
  const tokens = await pushRepository.findTokensByPolicialId(req.user.id);
  const diagnostics = fcmV1.getFcmDiagnostics();
  return {
    fcm_configured: diagnostics.configured,
    project_id: diagnostics.resolved_project_id,
    tokens_count: tokens.length,
    platforms: tokens.map((t) => t.platform),
    fcm_diagnostics: diagnostics,
  };
}

async function testPush(req) {
  const result = await sendPushToUser(req.user.id, {
    title: 'Teste — Permuta Policial',
    body: 'Push de teste recebido com sucesso.',
    data: { tipo: 'TESTE', referencia_id: '' },
  });
  return {
    ...result,
    ok: result.sent > 0,
    message:
      result.sent > 0
        ? 'Push de teste enviado.'
        : `Push não enviado: ${result.skipped || 'erro FCM'}`,
  };
}

module.exports = {
  registerDeviceToken,
  unregisterDeviceToken,
  getPushStatus,
  testPush,
};
