// /src/core/middlewares/auth.middleware.js
const jwt = require('jsonwebtoken');
const ApiError = require('../utils/ApiError');
const { fetchUserFromDb, assertUserVerified } = require('../utils/policial-auth.utils');
const { getCachedUser, setCachedUser } = require('./auth-user-cache');

module.exports = async (req, res, next) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return next(new ApiError(401, 'Token não fornecido. Acesso negado.'));
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const policialId = decoded.policial_id;

        if (!policialId) {
            return next(new ApiError(401, 'Token inválido: sem ID de usuário.'));
        }

        let policial = getCachedUser(policialId);
        if (!policial) {
            policial = await fetchUserFromDb(policialId);
            if (policial) {
                setCachedUser(policialId, policial);
            }
        }

        const verification = assertUserVerified(policial);
        if (!verification.ok) {
            return next(new ApiError(verification.statusCode, verification.message));
        }

        req.user = policial;
        next();
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return next(new ApiError(401, 'Token expirado.'));
        }
        return next(new ApiError(401, 'Token inválido.'));
    }
};
