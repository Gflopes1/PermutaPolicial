// /src/core/middlewares/verifiedAuth.middleware.js
// Middleware para verificar se o usuário tem status VERIFICADO

const ApiError = require('../utils/ApiError');

// Este middleware deve rodar SEMPRE *depois* do auth.middleware
module.exports = (req, res, next) => {
    // O auth.middleware já deve ter anexado o req.user
    if (!req.user) {
        return next(new ApiError(401, 'Usuário não autenticado.'));
    }

    // Verifica se o agente está verificado (usando a nova coluna agente_verificado)
    if (!req.user.agente_verificado || req.user.agente_verificado === 0) {
        return next(new ApiError(403, 'Acesso restrito. Sua conta precisa ser verificada para acessar este recurso. Entre em contato com um administrador.'));
    }

    next();
};

