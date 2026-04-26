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
                // ✅ SEGURANÇA: Seleciona apenas campos necessários
                let [userRows] = await db.execute(
                    `SELECT id, nome, email, qso, forca_id, unidade_atual_id, 
                     municipio_atual_id, posto_graduacao_id, embaixador, is_moderator,
                     agente_verificado, status_verificacao, is_premium, auth_provider,
                     google_id, microsoft_id, id_funcional, lotacao_interestadual,
                     ocultar_no_mapa, criado_em
                     FROM policiais WHERE google_id = ?`,
                    [id]
                );

                if (userRows.length > 0) {
                    console.log('✅ Usuário encontrado pelo Google ID');
                    return done(null, userRows[0]);
                }

                // 2. Se não, verifica se existe pelo email
                [userRows] = await db.execute(
                    `SELECT id, nome, email, qso, forca_id, unidade_atual_id, 
                     municipio_atual_id, posto_graduacao_id, embaixador, is_moderator,
                     agente_verificado, status_verificacao, is_premium, auth_provider,
                     google_id, microsoft_id, id_funcional, lotacao_interestadual,
                     ocultar_no_mapa, criado_em
                     FROM policiais WHERE email = ?`,
                    [email]
                );
                if (userRows.length > 0) {
                    console.log('⚠️  Usuário já existe com este email');
                    return done(new ApiError(409, 'Este email já está cadastrado. Por favor, faça login com sua senha.'), false);
                }

                // 3. Se não existe, cria novo usuário
                console.log('👤 Criando novo usuário Google');
                const [result] = await db.execute(
                    `INSERT INTO policiais (nome, email, google_id, auth_provider, status_verificacao)
           VALUES (?, ?, ?, 'google', 'VERIFICADO')`,
                    [displayName, email, id]
                );

                const [newUser] = await db.execute(
                    `SELECT id, nome, email, qso, forca_id, unidade_atual_id, 
                     municipio_atual_id, posto_graduacao_id, embaixador, is_moderator,
                     agente_verificado, status_verificacao, is_premium, auth_provider,
                     google_id, microsoft_id, id_funcional, lotacao_interestadual,
                     ocultar_no_mapa, criado_em
                     FROM policiais WHERE id = ?`,
                    [result.insertId]
                );
                console.log('✅ Novo usuário criado');

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