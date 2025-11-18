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

        // --- CORREÇÃO APLICADA AQUI ---
        // Buscamos o perfil completo do usuário, assim como o Passport faz.
        // Isso garante que o objeto req.user seja sempre consistente.
        const [rows] = await db.execute('SELECT * FROM policiais WHERE id = ?', [policialId]);

        if (rows.length === 0) {
            return next(new ApiError(401, 'Usuário do token não encontrado.'));
        }

        // Anexamos o objeto completo do usuário à requisição.
        req.user = rows[0];
        // --- FIM DA CORREÇÃO ---

        next();
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return next(new ApiError(401, 'Token expirado.'));
        }
        return next(new ApiError(401, 'Token inválido.'));
    }
};