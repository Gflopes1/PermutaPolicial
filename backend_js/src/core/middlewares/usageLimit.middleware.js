// /src/core/middlewares/usageLimit.middleware.js

const db = require('../../config/db');
const ApiError = require('../utils/ApiError');
const logger = require('../utils/logger');

/**
 * Incrementa uso diário de forma atômica e bloqueia se o limite foi atingido.
 */
async function tryConsumeDailyLimit(userId, featureName, maxLimit, today) {
    const [updateResult] = await db.execute(
        `UPDATE daily_usage_limits
         SET count = count + 1, updated_at = NOW()
         WHERE user_id = ? AND feature = ? AND usage_date = ? AND count < ?`,
        [userId, featureName, today, maxLimit]
    );

    if (updateResult.affectedRows === 1) {
        return true;
    }

    try {
        await db.execute(
            `INSERT INTO daily_usage_limits (user_id, feature, usage_date, count)
             VALUES (?, ?, ?, 1)`,
            [userId, featureName, today]
        );
        return true;
    } catch (insertError) {
        if (insertError.code !== 'ER_DUP_ENTRY') {
            throw insertError;
        }

        const [retryResult] = await db.execute(
            `UPDATE daily_usage_limits
             SET count = count + 1, updated_at = NOW()
             WHERE user_id = ? AND feature = ? AND usage_date = ? AND count < ?`,
            [userId, featureName, today, maxLimit]
        );
        return retryResult.affectedRows === 1;
    }
}

function usageLimitMiddleware(featureName, maxLimit) {
    return async (req, res, next) => {
        try {
            const isDevelopment = process.env.NODE_ENV !== 'production';

            if (!req.user?.id) {
                return next(new ApiError(401, 'Usuário não autenticado'));
            }

            const userId = req.user.id;
            const isPremium =
                req.user.is_premium === true || req.user.is_premium === 1;

            if (isPremium) {
                return next();
            }

            const today = new Date().toISOString().split('T')[0];
            const allowed = await tryConsumeDailyLimit(userId, featureName, maxLimit, today);

            if (!allowed) {
                if (isDevelopment) {
                    logger.log(`[usageLimit] Limite atingido user=${userId} feature=${featureName}`);
                }
                return next(new ApiError(
                    403,
                    `Limite diário atingido. Você pode usar esta funcionalidade ${maxLimit} vez(es) por dia. Torne-se Premium para uso ilimitado.`,
                    'LIMIT_REACHED'
                ));
            }

            if (isDevelopment) {
                logger.log(`[usageLimit] Uso registrado user=${userId} feature=${featureName}`);
            }

            next();
        } catch (error) {
            logger.error('[usageLimit] Erro no middleware de limite de uso', {
                error: error.message,
                code: error.code,
            });
            return next(new ApiError(500, `Erro ao verificar limite de uso: ${error.message}`));
        }
    };
}

module.exports = usageLimitMiddleware;
