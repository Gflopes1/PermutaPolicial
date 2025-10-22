// /src/core/middlewares/optionalAuth.middleware.js

const jwt = require('jsonwebtoken');
const db = require('../../config/db');

module.exports = async (req, res, next) => {
    const authHeader = req.headers.authorization;

    // Se não houver token, simplesmente continua sem um usuário autenticado
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return next();
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const [rows] = await db.execute('SELECT id, embaixador FROM policiais WHERE id = ?', [decoded.policial_id]);

        if (rows.length > 0) {
            // Anexa o usuário à requisição se o token for válido
            req.user = {
                id: rows[0].id,
                isEmbaixador: rows[0].embaixador === 1
            };
        }
    } catch (error) {
        // Ignora erros de token (expirado, inválido) e prossegue sem usuário
    }

    next();
};