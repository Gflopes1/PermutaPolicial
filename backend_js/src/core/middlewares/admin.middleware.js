// /src/core/middlewares/admin.middleware.js

const ApiError = require('../utils/ApiError');

// Este middleware deve rodar SEMPRE *depois* do auth.middleware
module.exports = (req, res, next) => {
    // O auth.middleware já deve ter anexado o req.user
    // O campo embaixador vem do banco como 0 ou 1
    // admin e moderador = embaixador
    const isEmbaixador = req.user && (req.user.embaixador === 1 || req.user.isEmbaixador === true);
    const isModerator = req.user && (req.user.is_moderator === 1 || req.user.is_moderator === true);
    
    if (!req.user || (!isEmbaixador && !isModerator)) {
        // Lança um erro que será capturado pelo nosso errorHandler central
        return next(new ApiError(403, 'Acesso negado. Recurso restrito a administradores.'));
    }
    next();
};