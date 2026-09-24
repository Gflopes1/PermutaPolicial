// Util compartilhado entre HTTP auth e Socket.IO
const db = require('../../config/db');

const BLOCKED_STATUSES = ['REJEITADO', 'AGUARDANDO_VERIFICACAO_EMAIL', 'NAO_VERIFICADO'];

const BLOCKED_MESSAGES = {
  REJEITADO: 'Sua conta foi rejeitada. Entre em contato com o suporte.',
  AGUARDANDO_VERIFICACAO_EMAIL: 'Confirme seu e-mail para acessar a plataforma.',
  NAO_VERIFICADO: 'Sua conta ainda não foi verificada.',
};

async function fetchUserFromDb(policialId) {
  const [rows] = await db.execute(
    `SELECT id, nome, email, qso, forca_id, unidade_atual_id,
     municipio_atual_id, posto_graduacao_id, embaixador, is_moderator,
     agente_verificado, status_verificacao, is_premium, auth_provider,
     google_id, microsoft_id, id_funcional, lotacao_interestadual,
     ocultar_no_mapa, criado_em
     FROM policiais WHERE id = ?`,
    [policialId]
  );
  return rows[0] || null;
}

function assertUserVerified(policial) {
  if (!policial) {
    return { ok: false, statusCode: 401, message: 'Usuário do token não encontrado.' };
  }
  if (BLOCKED_STATUSES.includes(policial.status_verificacao)) {
    return {
      ok: false,
      statusCode: 403,
      message: BLOCKED_MESSAGES[policial.status_verificacao] || 'Conta não autorizada.',
    };
  }
  if (policial.status_verificacao !== 'VERIFICADO') {
    return { ok: false, statusCode: 403, message: 'Conta não verificada.' };
  }
  return { ok: true };
}

module.exports = {
  BLOCKED_STATUSES,
  BLOCKED_MESSAGES,
  fetchUserFromDb,
  assertUserVerified,
};
