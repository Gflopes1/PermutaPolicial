function collectConnectOrigins() {
  const origins = new Set([
    "'self'",
    'https://www.gstatic.com',
    'https://fonts.gstatic.com',
    'https://static.cloudflareinsights.com',
  ]);

  for (const raw of [process.env.FRONTEND_URL, process.env.BASE_URL]) {
    if (!raw) continue;
    try {
      const url = new URL(raw);
      origins.add(url.origin);
      origins.add(`wss://${url.host}`);
    } catch (_) {
      // ignora URL inválida
    }
  }

  return [...origins].join(' ');
}

/** Headers necessários quando o Node serve o index.html do Flutter Web. */
function applyFlutterWebHeaders(res) {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');

  // Sobrescreve o Helmet: Flutter Web (CanvasKit) precisa de gstatic, fonts e wasm.
  res.setHeader(
    'Content-Security-Policy',
    [
      "default-src 'self'",
      "base-uri 'self'",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval' 'wasm-unsafe-eval' https://www.gstatic.com https://static.cloudflareinsights.com",
      `connect-src ${collectConnectOrigins()}`,
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: https: blob:",
      "font-src 'self' https://fonts.gstatic.com data:",
      "worker-src 'self' blob:",
      "child-src 'self' blob:",
    ].join('; ')
  );
}

module.exports = { applyFlutterWebHeaders };
