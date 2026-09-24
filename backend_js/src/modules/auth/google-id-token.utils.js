// Validação de ID Token do Google Sign-In nativo (APK) com JWKS

const { OAuth2Client } = require('google-auth-library');
const ApiError = require('../../core/utils/ApiError');

let oauth2Client;

function getOAuth2Client() {
  if (!oauth2Client) {
    oauth2Client = new OAuth2Client();
  }
  return oauth2Client;
}

function getAllowedAudiences() {
  return [
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_ANDROID_CLIENT_ID,
    process.env.GOOGLE_SERVER_CLIENT_ID,
  ].filter(Boolean);
}

/**
 * Verifica ID Token do Google usando google-auth-library (JWKS)
 * @param {string} idToken
 * @returns {Promise<{ sub: string, email: string, name: string, emailVerified: boolean }>}
 */
async function verifyGoogleIdToken(idToken) {
  if (!idToken || typeof idToken !== 'string') {
    throw new ApiError(400, 'Token do Google é obrigatório.');
  }

  const audiences = getAllowedAudiences();
  if (audiences.length === 0) {
    throw new ApiError(500, 'Configuração de autenticação do Google ausente.');
  }

  const client = getOAuth2Client();
  let ticket;
  
  try {
    ticket = await client.verifyIdToken({
      idToken,
      audience: audiences,
    });
  } catch (err) {
    throw new ApiError(401, 'Token do Google inválido ou expirado.');
  }

  const payload = ticket.getPayload();
  
  if (!payload) {
    throw new ApiError(401, 'Payload do token inválido.');
  }

  if (!payload.email_verified) {
    throw new ApiError(401, 'E-mail do Google não verificado.');
  }

  if (!payload.email) {
    throw new ApiError(401, 'Não foi possível obter o e-mail da conta Google.');
  }

  return {
    sub: payload.sub,
    email: payload.email,
    name: payload.name || payload.email.split('@')[0],
    emailVerified: true,
  };
}

module.exports = { verifyGoogleIdToken };
