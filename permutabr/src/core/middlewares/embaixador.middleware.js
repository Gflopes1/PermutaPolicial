// /src/core/middlewares/embaixador.middleware.js

const ApiError = require('../utils/ApiError');

// Middleware para verificar se o usuário é embaixador (pode aprovar questões)
// Embaixador tem acesso limitado - apenas aprovar questões
// Moderador/Admin tem acesso completo ao painel de admin
module.exports = (req, res, next) => {
    // O auth.middleware já deve ter anexado o req.user
    const isEmbaixador = req.user && (req.user.embaixador === 1 || req.user.isEmbaixador === true);
    const isModerator = req.user && (req.user.is_moderator === 1 || req.user.is_moderator === true);
    
    // Embaixador OU moderador/admin podem aprovar questões
    if (!req.user || (!isEmbaixador && !isModerator)) {
        return next(new ApiError(403, 'Acesso negado. Recurso restrito a embaixadores e moderadores.'));
    }
    
    // Anexa informação sobre o tipo de usuário para uso posterior
    req.user.isEmbaixadorOnly = isEmbaixador && !isModerator;
    req.user.isModerator = isModerator;
    
    next();
};

