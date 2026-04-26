// /src/core/middlewares/usageLimit.middleware.js

const db = require('../../config/db');
const ApiError = require('../utils/ApiError');

/**
 * Middleware para verificar e incrementar limites diários de uso
 * 
 * Se o usuário for Premium (is_premium = true), ignora o limite e permite acesso.
 * Se for Free, verifica na tabela daily_usage_limits:
 *   - Se count >= maxLimit, retorna erro 403 com code LIMIT_REACHED
 *   - Caso contrário, incrementa o contador e permite
 * 
 * @param {string} featureName - Nome da feature (ex: 'ai_consult', 'simulado_questions')
 * @param {number} maxLimit - Limite máximo diário para usuários Free
 * @returns {Function} Middleware function
 */
function usageLimitMiddleware(featureName, maxLimit) {
  return async (req, res, next) => {
    try {
      const isDevelopment = process.env.NODE_ENV !== 'production';
      
      if (isDevelopment) {
        console.log(`[usageLimit] Verificando: ${featureName}, limite: ${maxLimit}`);
      }
      
      // Verifica se o usuário está autenticado primeiro
      if (!req.user || !req.user.id) {
        if (isDevelopment) console.log('[usageLimit] Usuário não autenticado');
        return next(new ApiError(401, 'Usuário não autenticado'));
      }

      const userId = req.user.id;

      // O premium.middleware deve ter sido executado antes
      // e anexado req.user.is_premium
      // Verifica também o campo direto do banco como fallback
      const isPremium = req.user?.is_premium === true || 
                       req.user?.is_premium === 1 || 
                       false;

      if (isDevelopment) {
        console.log(`[usageLimit] User ${userId} - Premium: ${isPremium}`);
      }

      // Se for Premium, ignora limite
      if (isPremium) {
        return next();
      }

      const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

      // Busca ou cria registro de uso diário
      let [rows] = [];
      try {
        [rows] = await db.execute(
          `SELECT id, count FROM daily_usage_limits 
           WHERE user_id = ? AND feature = ? AND usage_date = ?`,
          [userId, featureName, today]
        );
      } catch (dbError) {
        const isDevelopment = process.env.NODE_ENV !== 'production';
        
        // Se a tabela não existe ou há erro de conexão, permite acesso mas loga
        // Não quebra o servidor - apenas permite acesso sem controle de limite
        if (dbError.code === 'ER_NO_SUCH_TABLE' || 
            dbError.code === 'ER_BAD_TABLE_ERROR' ||
            dbError.message?.includes('doesn\'t exist') ||
            dbError.message?.includes('Table') && dbError.message?.includes('doesn\'t exist')) {
          console.error('[usageLimit] ⚠️ ERRO CRÍTICO: Tabela daily_usage_limits não existe!');
          console.error('[usageLimit] Execute a migration: create_daily_usage_limits.sql');
          // Permite acesso sem controle de limite se a tabela não existe
          return next();
        }
        // Para outros erros de banco, também permite acesso para não quebrar o servidor
        console.error('[usageLimit] Erro de banco de dados:', dbError.message);
        if (isDevelopment) {
          console.error('[usageLimit] Stack:', dbError.stack);
        }
        return next();
      }

      let currentCount = 0;
      let recordId = null;

      if (rows.length > 0) {
        recordId = rows[0].id;
        currentCount = rows[0].count;
        if (isDevelopment) {
          console.log(`[usageLimit] User ${userId} - Count atual: ${currentCount}/${maxLimit}`);
        }
      }

      // Verifica se já atingiu o limite
      if (currentCount >= maxLimit) {
        if (isDevelopment) {
          console.log(`[usageLimit] ⚠️ Limite atingido para user ${userId}: ${currentCount}/${maxLimit}`);
        }
        return next(new ApiError(
          403,
          `Limite diário atingido. Você pode usar esta funcionalidade ${maxLimit} vez(es) por dia. Torne-se Premium para uso ilimitado.`,
          'LIMIT_REACHED'
        ));
      }

      // Incrementa o contador (upsert)
      try {
        if (recordId) {
          // Atualiza registro existente
          await db.execute(
            `UPDATE daily_usage_limits 
             SET count = count + 1, updated_at = NOW() 
             WHERE id = ?`,
            [recordId]
          );
        } else {
          // Cria novo registro usando INSERT ... ON DUPLICATE KEY UPDATE para evitar race conditions
          await db.execute(
            `INSERT INTO daily_usage_limits (user_id, feature, usage_date, count) 
             VALUES (?, ?, ?, 1)
             ON DUPLICATE KEY UPDATE count = count + 1, updated_at = NOW()`,
            [userId, featureName, today]
          );
        }
        if (isDevelopment) {
          console.log(`[usageLimit] ✅ Contador incrementado: ${currentCount + 1}/${maxLimit}`);
        }
      } catch (insertError) {
        console.error('[usageLimit] Erro ao inserir/atualizar registro:', insertError.message);
        // Em caso de erro, permite acesso mas loga
        // Não quebra o servidor - apenas permite acesso sem incrementar contador
        if (isDevelopment) {
          console.warn('[usageLimit] ⚠️ Permitindo acesso sem incrementar contador');
        }
      }

      // Permite acesso
      next();
    } catch (error) {
      console.error('[usageLimit] ERRO no middleware de limite de uso:', error);
      console.error('[usageLimit] Stack trace:', error.stack);
      // Se for erro de tabela não encontrada, retorna erro mais específico
      if (error.code === 'ER_NO_SUCH_TABLE' || error.message.includes('doesn\'t exist')) {
        console.error('[usageLimit] Tabela daily_usage_limits não existe no banco de dados!');
        return next(new ApiError(500, 'Tabela de limites não encontrada. Contate o administrador.'));
      }
      return next(new ApiError(500, `Erro ao verificar limite de uso: ${error.message}`));
    }
  };
}

module.exports = usageLimitMiddleware;

