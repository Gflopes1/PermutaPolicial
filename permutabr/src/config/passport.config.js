// /src/config/passport.config.js

const passport = require('passport');
const db = require('./db');
const logger = require('../core/utils/logger');
const createGoogleStrategy = require('./passport/google.strategy');
const createMicrosoftStrategy = require('./passport/microsoft.strategy');
const policiaisOAuthRepository = require('../modules/policiais/policiais.oauth.repository');

/**
 * Configura o Passport com todas as estratégias OAuth
 * @param {Object} options - Opções de configuração
 * @param {boolean} options.allowHttpForRedirectUrl - Permite HTTP para redirect URL (útil em desenvolvimento)
 */
function configurePassport(options = {}) {
    // Configura estratégias OAuth
    passport.use('google', createGoogleStrategy());
    passport.use('microsoft', createMicrosoftStrategy({
        allowHttpForRedirectUrl: options.allowHttpForRedirectUrl || false
    }));

    // Serialização do usuário
    passport.serializeUser((user, done) => {
        done(null, user.id);
    });

    // Deserialização do usuário
    passport.deserializeUser(async (id, done) => {
        try {
            const user = await policiaisOAuthRepository.findById(id);
            done(null, user);
        } catch (error) {
            logger.error('Erro ao deserializar usuário', { error: error.message });
            done(error, null);
        }
    });

    logger.debug('Passport configurado');
}

module.exports = {
    configurePassport
};

