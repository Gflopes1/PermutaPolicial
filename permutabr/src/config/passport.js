const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const db = require('./db');
const ApiError = require('../core/utils/ApiError');

// Exporta uma função que configura o passport
module.exports = function () {
    console.log('🔐 Configurando Google Strategy...');

    passport.use('google', new GoogleStrategy({
        clientID: process.env.GOOGLE_CLIENT_ID,
        clientSecret: process.env.GOOGLE_CLIENT_SECRET,
        callbackURL: process.env.GOOGLE_CALLBACK_URL || '/api/auth/google/callback'
    },
        async (accessToken, refreshToken, profile, done) => {
            try {
                console.log('🔐 Google OAuth Profile:', profile.id);

                const { id, displayName, emails } = profile;
                const email = emails[0].value;

                // 1. Verifica se o usuário já existe pelo google_id
                let [userRows] = await db.execute('SELECT * FROM policiais WHERE google_id = ?', [id]);

                if (userRows.length > 0) {
                    console.log('✅ Usuário encontrado pelo Google ID:', userRows[0].email);
                    return done(null, userRows[0]);
                }

                // 2. Se não, verifica se existe pelo email
                [userRows] = await db.execute('SELECT * FROM policiais WHERE email = ?', [email]);
                if (userRows.length > 0) {
                    console.log('⚠️  Usuário já existe com este email:', email);
                    return done(new ApiError(409, 'Este email já está cadastrado. Por favor, faça login com sua senha.'), false);
                }

                // 3. Se não existe, cria novo usuário
                console.log('👤 Criando novo usuário Google:', email);
                const [result] = await db.execute(
                    `INSERT INTO policiais (nome, email, google_id, auth_provider, status_verificacao)
           VALUES (?, ?, ?, 'google', 'VERIFICADO')`,
                    [displayName, email, id]
                );

                const [newUser] = await db.execute('SELECT * FROM policiais WHERE id = ?', [result.insertId]);
                console.log('✅ Novo usuário criado:', newUser[0].email);

                return done(null, newUser[0]);

            } catch (error) {
                console.error('💥 Erro no Google OAuth:', error);
                return done(error, false);
            }
        }
    ));

    console.log('✅ Google Strategy configurada com sucesso!');

    return passport;
};