// Cliente FCM HTTP v1 (OAuth2 + service account) — substitui a API legacy descontinuada.

const fs = require('fs');
const path = require('path');
const axios = require('axios');
const { GoogleAuth } = require('google-auth-library');
const logger = require('../../core/utils/logger');

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

/** Raiz do projeto API (/www/wwwroot/permutabr_api) */
const PROJECT_ROOT = path.resolve(__dirname, '../../..');

const DEFAULT_CREDENTIAL_FILES = [
  path.join(PROJECT_ROOT, 'firebase-service-account.json'),
  path.join(PROJECT_ROOT, 'secrets', 'firebase-service-account.json'),
  path.join(PROJECT_ROOT, 'fcm-service-account.json'),
];

let cachedAuth = null;
let cachedProjectId = null;
let lastLoadError = null;

function normalizeInlineJson(raw) {
  let s = String(raw).trim();
  if (
    (s.startsWith("'") && s.endsWith("'")) ||
    (s.startsWith('"') && s.endsWith('"'))
  ) {
    s = s.slice(1, -1);
  }
  return s.trim();
}

function parseServiceAccountJson(raw) {
  const normalized = normalizeInlineJson(raw);
  try {
    return JSON.parse(normalized);
  } catch (firstError) {
    try {
      return JSON.parse(normalized.replace(/\\n/g, '\n'));
    } catch {
      throw new Error(`JSON malformado: ${firstError.message}`);
    }
  }
}

/** dotenv não suporta JSON multilinha — só carrega FCM_SERVICE_ACCOUNT_JSON={ */
function isBrokenInlineJson(value) {
  const trimmed = String(value).trim();
  if (!trimmed || trimmed === '{' || trimmed.length < 40) return true;
  if (trimmed.startsWith('{') && !trimmed.includes('"type"')) return true;
  return false;
}

function loadFromDefaultCredentialFiles() {
  for (const filePath of DEFAULT_CREDENTIAL_FILES) {
    if (!fs.existsSync(filePath)) continue;
    try {
      const raw = fs.readFileSync(filePath, 'utf8');
      logger.log(`[push] Credenciais FCM carregadas de ${filePath}`);
      return parseServiceAccountJson(raw);
    } catch (error) {
      lastLoadError = `Erro ao ler ${filePath}: ${error.message}`;
    }
  }
  return null;
}

function resolveProjectId() {
  if (cachedProjectId) return cachedProjectId;

  const fromEnv =
    process.env.FCM_PROJECT_ID ||
    process.env.FIREBASE_PROJECT_ID ||
    null;
  if (fromEnv) {
    cachedProjectId = fromEnv;
    return cachedProjectId;
  }

  try {
    const credentials = loadServiceAccountCredentials();
    if (credentials?.project_id) {
      cachedProjectId = credentials.project_id;
      return cachedProjectId;
    }
  } catch (_) {
    // Ignora — isFcmConfigured tratará ausência de credenciais.
  }

  return null;
}

function loadServiceAccountCredentials() {
  lastLoadError = null;

  const b64 = process.env.FCM_SERVICE_ACCOUNT_JSON_B64;
  if (b64 && String(b64).trim()) {
    try {
      const decoded = Buffer.from(String(b64).trim(), 'base64').toString('utf8');
      return parseServiceAccountJson(decoded);
    } catch (error) {
      lastLoadError = `FCM_SERVICE_ACCOUNT_JSON_B64 inválido: ${error.message}`;
      throw new Error(lastLoadError);
    }
  }

  const inlineJson = process.env.FCM_SERVICE_ACCOUNT_JSON;
  if (inlineJson && String(inlineJson).trim()) {
    if (isBrokenInlineJson(inlineJson)) {
      lastLoadError =
        'FCM_SERVICE_ACCOUNT_JSON multilinha no .env — dotenv só lê a 1ª linha ("{"). ' +
        'Salve o JSON em firebase-service-account.json na raiz da API ou use FCM_SERVICE_ACCOUNT_PATH.';
    } else {
      try {
        return parseServiceAccountJson(inlineJson);
      } catch (error) {
        lastLoadError = `FCM_SERVICE_ACCOUNT_JSON inválido: ${error.message}`;
        throw new Error(lastLoadError);
      }
    }
  }

  const credPath =
    process.env.FCM_SERVICE_ACCOUNT_PATH ||
    process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    null;

  if (credPath) {
    const absolute = path.isAbsolute(credPath)
      ? credPath
      : path.resolve(PROJECT_ROOT, credPath);

    if (!fs.existsSync(absolute)) {
      lastLoadError = `Arquivo de service account não encontrado: ${absolute}`;
      throw new Error(lastLoadError);
    }

    try {
      const raw = fs.readFileSync(absolute, 'utf8');
      return parseServiceAccountJson(raw);
    } catch (error) {
      lastLoadError = `Erro ao ler ${absolute}: ${error.message}`;
      throw error;
    }
  }

  const fromDefault = loadFromDefaultCredentialFiles();
  if (fromDefault) {
    return fromDefault;
  }

  if (!lastLoadError) {
    lastLoadError =
      'Nenhuma credencial FCM. Crie /www/wwwroot/permutabr_api/firebase-service-account.json ' +
      'ou defina FCM_SERVICE_ACCOUNT_PATH no .env (JSON multilinha no .env não funciona).';
  }
  return null;
}

function getGoogleAuth() {
  if (cachedAuth) return cachedAuth;

  const credentials = loadServiceAccountCredentials();
  if (!credentials) {
    return null;
  }

  cachedAuth = new GoogleAuth({
    credentials,
    scopes: [FCM_SCOPE],
  });

  return cachedAuth;
}

async function getAccessToken() {
  return getAccessTokenForScopes([FCM_SCOPE]);
}

/**
 * OAuth2 com o mesmo service account do FCM (JSON / path / B64).
 * @param {string[]} scopes ex.: cloud-vision, cloud-platform
 */
async function getAccessTokenForScopes(scopes) {
  const credentials = loadServiceAccountCredentials();
  if (!credentials) {
    throw new Error(
      lastLoadError ||
        'Service account não configurado. Defina FCM_SERVICE_ACCOUNT_PATH ou firebase-service-account.json.'
    );
  }

  const auth = new GoogleAuth({ credentials, scopes });
  const client = await auth.getClient();
  const tokenResponse = await client.getAccessToken();
  const token = typeof tokenResponse === 'string' ? tokenResponse : tokenResponse?.token;

  if (!token) {
    throw new Error('Não foi possível obter access token OAuth2 do service account.');
  }

  return token;
}

function isServiceAccountConfigured() {
  try {
    return Boolean(loadServiceAccountCredentials());
  } catch (_) {
    return false;
  }
}

function buildNotificationDeepLink(tipo, referenciaId) {
  const webBase =
    process.env.FCM_WEB_LINK_BASE ||
    process.env.FRONTEND_URL ||
    'https://br.permutapolicial.com.br';
  const base = webBase.replace(/\/$/, '');
  const ref = referenciaId != null && referenciaId !== '' ? String(referenciaId) : null;

  switch (tipo) {
    case 'NOVA_MENSAGEM':
      return ref ? `${base}/chat/conversa/${ref}` : `${base}/dashboard`;
    case 'NOVO_MATCH':
      return `${base}/permutas`;
    case 'SOLICITACAO_CONTATO':
    case 'SOLICITACAO_CONTATO_ACEITA':
      return `${base}/notificacoes`;
    case 'MAPA_TATICO_CONVITE':
      return `${base}/mapa-tatico`;
    case 'MAPA_TATICO_PONTO':
    case 'MAPA_TATICO_COMENTARIO':
    case 'MAPA_TATICO_DENUNCIA':
    case 'MAPA_TATICO_PROXIMIDADE':
      return ref ? `${base}/mapa-tatico/ponto/${ref}` : `${base}/mapa-tatico`;
    default:
      return base;
  }
}

function buildMessagePayload({ token, platform, title, body, data = {} }) {
  const stringData = Object.fromEntries(
    Object.entries(data).map(([k, v]) => [k, v == null ? '' : String(v)])
  );

  const message = {
    token,
    notification: { title, body },
    data: stringData,
    android: {
      priority: 'HIGH',
      notification: {
        sound: 'default',
        channel_id: 'permuta_policial_default',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  };

  if (platform === 'web') {
    const webBase =
      process.env.FCM_WEB_LINK_BASE ||
      process.env.FRONTEND_URL ||
      'https://br.permutapolicial.com.br';
    const origin = webBase.replace(/\/$/, '');
    const link = buildNotificationDeepLink(data.tipo, data.referencia_id);

    message.webpush = {
      headers: { Urgency: 'high' },
      notification: {
        title,
        body,
        icon: `${origin}/icons/Icon-192.png`,
      },
      fcm_options: {
        link,
      },
    };
  }

  return { message };
}

/**
 * @returns {{ ok: boolean, errorCode?: string, errorMessage?: string }}
 */
async function sendToToken(token, platform, { title, body, data }) {
  const projectId = resolveProjectId();
  if (!projectId) {
    throw new Error('FCM_PROJECT_ID (ou FIREBASE_PROJECT_ID) não configurado.');
  }

  const accessToken = await getAccessToken();
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const payload = buildMessagePayload({ token, platform, title, body, data });

  try {
    await axios.post(url, payload, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      timeout: 15000,
    });
    return { ok: true };
  } catch (error) {
    const status = error.response?.status;
    const errBody = error.response?.data?.error;
    const errorCode = errBody?.details?.[0]?.errorCode || errBody?.status || 'UNKNOWN';
    const errorMessage = errBody?.message || error.message;

    return {
      ok: false,
      status,
      errorCode,
      errorMessage,
    };
  }
}

function isInvalidTokenError(errorCode, status) {
  const code = String(errorCode || '').toUpperCase();
  return (
    status === 404 ||
    code === 'UNREGISTERED' ||
    code === 'INVALID_ARGUMENT' ||
    code === 'NOT_FOUND'
  );
}

function isFcmConfigured() {
  try {
    return Boolean(getGoogleAuth() && resolveProjectId());
  } catch (error) {
    lastLoadError = error.message;
    return false;
  }
}

/**
 * Diagnóstico seguro (sem expor segredos) — use GET /api/push/status
 */
function getFcmDiagnostics() {
  let credentials = null;
  let parseOk = false;

  try {
    credentials = loadServiceAccountCredentials();
    parseOk = Boolean(credentials?.client_email && credentials?.private_key);
  } catch (error) {
    lastLoadError = error.message;
  }

  const credPath =
    process.env.FCM_SERVICE_ACCOUNT_PATH ||
    process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    null;
  let pathExists = null;
  if (credPath) {
    const absolute = path.isAbsolute(credPath)
      ? credPath
      : path.resolve(PROJECT_ROOT, credPath);
    pathExists = fs.existsSync(absolute);
  }

  const defaultFilesStatus = DEFAULT_CREDENTIAL_FILES.map((filePath) => ({
    path: filePath,
    exists: fs.existsSync(filePath),
  }));

  return {
    configured: isFcmConfigured(),
    project_root: PROJECT_ROOT,
    cwd: process.cwd(),
    env: {
      has_FCM_PROJECT_ID: Boolean(process.env.FCM_PROJECT_ID),
      has_FIREBASE_PROJECT_ID: Boolean(process.env.FIREBASE_PROJECT_ID),
      has_FCM_SERVICE_ACCOUNT_JSON: Boolean(process.env.FCM_SERVICE_ACCOUNT_JSON),
      FCM_SERVICE_ACCOUNT_JSON_length: process.env.FCM_SERVICE_ACCOUNT_JSON
        ? String(process.env.FCM_SERVICE_ACCOUNT_JSON).length
        : 0,
      inline_json_broken: process.env.FCM_SERVICE_ACCOUNT_JSON
        ? isBrokenInlineJson(process.env.FCM_SERVICE_ACCOUNT_JSON)
        : false,
      has_FCM_SERVICE_ACCOUNT_JSON_B64: Boolean(process.env.FCM_SERVICE_ACCOUNT_JSON_B64),
      has_FCM_SERVICE_ACCOUNT_PATH: Boolean(process.env.FCM_SERVICE_ACCOUNT_PATH),
      cred_path_exists: pathExists,
    },
    default_credential_files: defaultFilesStatus,
    resolved_project_id: resolveProjectId(),
    service_account_email: credentials?.client_email || null,
    credentials_parse_ok: parseOk,
    last_error: lastLoadError,
  };
}

function logFcmStartupStatus() {
  const d = getFcmDiagnostics();
  if (d.configured) {
    logger.log(
      `[push] FCM v1 OK project=${d.resolved_project_id} account=${d.service_account_email}`
    );
  } else {
    console.warn('[push] FCM v1 NÃO configurado:', JSON.stringify(d));
  }
}

module.exports = {
  sendToToken,
  isInvalidTokenError,
  isFcmConfigured,
  isServiceAccountConfigured,
  resolveProjectId,
  getAccessTokenForScopes,
  loadServiceAccountCredentials,
  getFcmDiagnostics,
  logFcmStartupStatus,
};
