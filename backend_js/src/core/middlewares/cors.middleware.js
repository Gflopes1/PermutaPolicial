const cors = require('cors');

function parseOriginList(value) {
  if (!value) return [];
  return value.split(',').map((item) => item.trim()).filter(Boolean);
}

function isNoOriginAllowedPath(pathname) {
  const p = String(pathname || '').toLowerCase();
  return (
    p === '/health' ||
    p.startsWith('/api/payments/webhook')
  );
}

function buildAllowedOrigins(extraOrigins = []) {
  return [
    process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br',
    'https://br.permutapolicial.com.br',
    'https://dev.br.permutapolicial.com.br',
    'http://dev.br.permutapolicial.com.br',
    'https://login.microsoftonline.com',
    'https://www.mercadopago.com.br',
    'https://mercadopago.com.br',
    ...(process.env.NODE_ENV === 'development'
      ? ['http://localhost:3000', 'http://localhost:8080', 'http://localhost:5000']
      : []),
    ...extraOrigins,
  ];
}

function createCorsMiddleware({ extraOrigins = [], allowPrivateLanInDev = false } = {}) {
  const allowedOrigins = buildAllowedOrigins(extraOrigins);

  return (req, res, next) => {
    cors({
      origin(origin, callback) {
        if (!origin) {
          if (
            process.env.NODE_ENV === 'development' ||
            isNoOriginAllowedPath(req.path)
          ) {
            return callback(null, true);
          }
          return callback(null, false);
        }

        if (allowedOrigins.includes(origin)) {
          return callback(null, true);
        }

        if (process.env.NODE_ENV === 'development') {
          if (
            origin.startsWith('http://localhost:') ||
            origin.startsWith('http://127.0.0.1:') ||
            (allowPrivateLanInDev &&
              (origin.startsWith('http://192.168.') ||
                origin.startsWith('http://10.') ||
                origin.startsWith('http://172.')))
          ) {
            return callback(null, true);
          }
        }

        return callback(null, false);
      },
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: [
        'Content-Type',
        'Authorization',
        'x-signature',
        'x-mercadopago-signature',
        'x-request-id',
      ],
    })(req, res, next);
  };
}

module.exports = {
  createCorsMiddleware,
  parseOriginList,
  isNoOriginAllowedPath,
};
