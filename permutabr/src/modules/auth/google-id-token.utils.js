// Validação de ID Token do Google Sign-In nativo (APK)

const axios = require('axios');
const ApiError = require('../../core/utils/ApiError');

const TOKEN_INFO_URL = 'https://oauth2.googleapis.com/tokeninfo';

function getAllowedAudiences() {
  return [
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_ANDROID_CLIENT_ID,
    process.env.GOOGLE_SERVER_CLIENT_ID,
  ].filter(Boolean);
}

/**
 * @param {string} idToken
 * @returns {Promise<{ sub: string, email: string, name: string, emailVerified: boolean }>}
 */
async function verifyGoogleIdToken(idToken) {
  if (!idToken || typeof idToken !== 'string') {
    throw new ApiError(400, 'Token do Google é obrigatório.');
  }

  let data;
  try {
    const response = await axios.get(TOKEN_INFO_URL, {
      params: { id_token: idToken },
      timeout: 10000,
    });
    data = response.data;
  } catch (err) {
    throw new ApiError(401, 'Token do Google inválido ou expirado.');
  }

  const audiences = getAllowedAudiences();
  if (audiences.length > 0 && !audiences.includes(data.aud)) {
    throw new ApiError(401, 'Token do Google não autorizado para este aplicativo.');
  }

  if (data.email_verified !== 'true' && data.email_verified !== true) {
    throw new ApiError(401, 'E-mail do Google não verificado.');
  }

  if (!data.email) {
    throw new ApiError(401, 'Não foi possível obter o e-mail da conta Google.');
  }

  return {
    sub: data.sub,
    email: data.email,
    name: data.name || data.email.split('@')[0],
    emailVerified: true,
  };
}

module.exports = { verifyGoogleIdToken };
