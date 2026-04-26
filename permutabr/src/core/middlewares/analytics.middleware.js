// /src/core/middlewares/analytics.middleware.js

const analyticsService = require('../../modules/analytics/analytics.service');

// Middleware para rastrear automaticamente page views
const trackPageView = async (req, res, next) => {
  // Não rastreia requisições de API ou assets
  if (req.path.startsWith('/api/') || 
      req.path.match(/\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$/)) {
    return next();
  }

  // Rastreia apenas requisições GET para páginas
  if (req.method === 'GET') {
    const sessaoId = req.headers['x-session-id'] || req.cookies?.session_id || null;
    
    if (sessaoId) {
      // Registra page view de forma assíncrona (não bloqueia a resposta)
      analyticsService.registrarPageView({
        usuario_id: req.user?.id || null,
        pagina: req.path,
        sessao_id: sessaoId,
        ip_address: req.ip || req.connection.remoteAddress,
        user_agent: req.get('user-agent'),
      }).catch(err => {
        // Log silencioso de erros de analytics
        if (process.env.NODE_ENV === 'development') {
          console.error('Erro ao registrar page view:', err);
        }
      });
    }
  }

  next();
};

module.exports = trackPageView;

