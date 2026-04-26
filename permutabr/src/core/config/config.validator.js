// /src/core/config/config.validator.js

const logger = require('../utils/logger');

/**
 * Valida variáveis de ambiente obrigatórias
 */
function validateConfig() {
    const requiredVars = [
        'DB_HOST',
        'DB_USER',
        'DB_PASSWORD',
        'DB_NAME',
        'JWT_SECRET',
        'SESSION_SECRET'
    ];

    const missingVars = [];
    const warnings = [];

    // Valida variáveis obrigatórias
    for (const varName of requiredVars) {
        if (!process.env[varName]) {
            missingVars.push(varName);
        }
    }

    // Valida variáveis opcionais mas recomendadas
    if (!process.env.BASE_URL) {
        warnings.push('BASE_URL não configurado - usando valor padrão');
    }

    if (!process.env.FRONTEND_URL) {
        warnings.push('FRONTEND_URL não configurado - usando valor padrão');
    }

    // Valida configurações OAuth (opcional, mas recomendado)
    if (!process.env.GOOGLE_CLIENT_ID || !process.env.GOOGLE_CLIENT_SECRET) {
        warnings.push('Google OAuth não configurado - login com Google não funcionará');
    }

    if (!process.env.MICROSOFT_CLIENT_ID || !process.env.MICROSOFT_CLIENT_SECRET) {
        warnings.push('Microsoft OAuth não configurado - login com Microsoft não funcionará');
    }

    // Valida configurações de email (opcional, mas recomendado)
    if (!process.env.MAIL_HOST || !process.env.MAIL_USER || !process.env.MAIL_PASS) {
        warnings.push('Email não configurado - funcionalidades de email não funcionarão');
    }

    // Se faltam variáveis obrigatórias, lança erro
    if (missingVars.length > 0) {
        const errorMsg = `Variáveis de ambiente obrigatórias não configuradas: ${missingVars.join(', ')}`;
        logger.critical(errorMsg);
        throw new Error(errorMsg);
    }

    // Loga avisos em desenvolvimento
    if (warnings.length > 0 && process.env.NODE_ENV !== 'production') {
        warnings.forEach(warning => {
            logger.warn(warning);
        });
    }

    logger.debug('Validação de configuração concluída', {
        missing: missingVars.length,
        warnings: warnings.length
    });
}

module.exports = {
    validateConfig
};

