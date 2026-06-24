// /src/core/utils/frontend-url.utils.js

const DEFAULT_FRONTEND = 'https://br.permutapolicial.com.br';

function getAllowedFrontendOrigins() {
  const origins = new Set([
    process.env.FRONTEND_URL,
    DEFAULT_FRONTEND,
    'https://dev.br.permutapolicial.com.br',
  ]);

  if (process.env.NODE_ENV === 'development') {
    origins.add('http://localhost:8080');
    origins.add('http://localhost:3000');
    origins.add('http://localhost:5000');
  }

  if (process.env.ALLOWED_FRONTEND_ORIGINS) {
    process.env.ALLOWED_FRONTEND_ORIGINS.split(',').forEach((o) => {
      const trimmed = o.trim();
      if (trimmed) origins.add(trimmed);
    });
  }

  return [...origins].filter(Boolean);
}

function normalizeOrigin(origin) {
  if (!origin || typeof origin !== 'string') return null;
  try {
    const url = new URL(origin);
    return `${url.protocol}//${url.host}`;
  } catch {
    return null;
  }
}

function isAllowedFrontendOrigin(origin) {
  const normalized = normalizeOrigin(origin);
  if (!normalized) return false;

  const allowed = getAllowedFrontendOrigins()
    .map(normalizeOrigin)
    .filter(Boolean);

  return allowed.includes(normalized);
}

function resolveSafeFrontendOrigin(candidate, fallback) {
  const defaultUrl = normalizeOrigin(fallback)
    || normalizeOrigin(process.env.FRONTEND_URL)
    || DEFAULT_FRONTEND;

  if (candidate && isAllowedFrontendOrigin(candidate)) {
    return normalizeOrigin(candidate);
  }

  return defaultUrl;
}

function saveOAuthOriginToSession(req, origin) {
  if (!origin || !isAllowedFrontendOrigin(origin)) {
    return false;
  }
  req.session = req.session || {};
  req.session.oauthOrigin = normalizeOrigin(origin);
  return true;
}

module.exports = {
  getAllowedFrontendOrigins,
  normalizeOrigin,
  isAllowedFrontendOrigin,
  resolveSafeFrontendOrigin,
  saveOAuthOriginToSession,
};
