// /src/core/middlewares/auth.middleware.js
const jwt = require('jsonwebtoken');
const db = require('../../config/db');
const ApiError = require('../utils/ApiError');

module.exports = async (req, res, next) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return next(new ApiError(401, 'Token não fornecido. Acesso negado.'));
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const policialId = decoded.policial_id; // Padronizado para usar apenas policial_id

        if (!policialId) {
            return next(new ApiError(401, 'Token inválido: sem ID de usuário.'));
        }

        // ✅ SEGURANÇA: Seleciona apenas campos necessários, excluindo dados sensíveis
        const [rows] = await db.execute(
            `SELECT id, nome, email, qso, forca_id, unidade_atual_id, 
             municipio_atual_id, posto_graduacao_id, embaixador, is_moderator,
             agente_verificado, status_verificacao, is_premium, auth_provider,
             google_id, microsoft_id, id_funcional, lotacao_interestadual,
             ocultar_no_mapa, criado_em
             FROM policiais WHERE id = ?`,
            [policialId]
        );

        if (rows.length === 0) {
            return next(new ApiError(401, 'Usuário do token não encontrado.'));
        }

        // Anexa apenas os campos seguros à requisição
        req.user = rows[0];

        next();
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return next(new ApiError(401, 'Token expirado.'));
        }
        return next(new ApiError(401, 'Token inválido.'));
    }
};