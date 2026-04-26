// /src/config/passport/google.strategy.js

const GoogleStrategy = require('passport-google-oauth20').Strategy;
const oauthService = require('../../modules/auth/oauth.service');
const logger = require('../../core/utils/logger');

function createGoogleStrategy() {
    const callbackURL = process.env.GOOGLE_CALLBACK_URL || 
                        `${process.env.BASE_URL || 'https://br.permutapolicial.com.br'}/api/auth/google/callback`;
    
    logger.debug(`URL de Callback do Google: ${callbackURL}`);

    return new GoogleStrategy({
        clientID: process.env.GOOGLE_CLIENT_ID,
        clientSecret: process.env.GOOGLE_CLIENT_SECRET,
        callbackURL: callbackURL,
        proxy: true
    },
    async (accessToken, refreshToken, profile, done) => {
        try {
            const email = profile.emails[0].value;
            const googleId = profile.id;
            logger.debug('Login Google OAuth', { email });

            const user = await oauthService.processOAuth({
                providerId: googleId,
                providerName: 'google',
                email,
                nome: profile.displayName
            });

            return done(null, user);
        } catch (error) {
            logger.error('Erro OAuth Google', {
                error: error.message,
                stack: error.stack
            });
            return done(error, false);
        }
    });
}

module.exports = createGoogleStrategy;

