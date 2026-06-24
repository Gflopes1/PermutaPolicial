// Proxy público de imagens R2 — mesma origem da API, sem CORS no Flutter web.

const express = require('express');
const storageService = require('../../core/services/storage.service');
const logger = require('../../core/utils/logger');

const router = express.Router();

const ALLOWED_PREFIXES = ['mapa-tatico/', 'marketplace/', 'consultoria-juridica/'];

async function serveR2Object(key, res, next) {
  if (!key || !ALLOWED_PREFIXES.some((prefix) => key.startsWith(prefix)) || key.includes('..')) {
    return res.status(404).end();
  }

  try {
    const { stream, contentType, contentLength, etag } = await storageService.getObject(key);

    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'public, max-age=86400, stale-while-revalidate=604800');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    if (contentLength) res.setHeader('Content-Length', String(contentLength));
    if (etag) res.setHeader('ETag', etag);

    stream.on('error', (err) => {
      logger.error('[CDN proxy] Erro ao transmitir objeto', { key, message: err.message });
      if (!res.headersSent) res.status(500).end();
    });

    stream.pipe(res);
  } catch (error) {
    const status = error.$metadata?.httpStatusCode;
    if (status === 404 || error.name === 'NoSuchKey') {
      return res.status(404).end();
    }
    logger.error('[CDN proxy] Falha ao buscar objeto R2', {
      key,
      errorName: error.name,
      errorMessage: error.message,
      httpStatus: status,
    });
    next(error);
  }
}

// Formato preferido: /api/cdn?key=mapa-tatico/2026/foto.jpg
// (sem extensão no path — regras de estáticos do Nginx não interceptam)
router.get('/cdn', (req, res, next) => {
  const key = typeof req.query.key === 'string' ? req.query.key : '';
  return serveR2Object(key, res, next);
});

// Formato legado com key no path (pode ser capturado por regras de estáticos do Nginx)
router.get(/^\/cdn\/(.+)$/, (req, res, next) => {
  return serveR2Object(req.params[0], res, next);
});

module.exports = router;
