// /server.dev.js - Servidor para ambiente de desenvolvimento

require('dotenv').config({ path: '.env.dev' });

console.log('═══════════════════════════════════════');
console.log('🚀 Iniciando aplicação em DESENVOLVIMENTO...');
console.log('📍 Ambiente:', process.env.NODE_ENV || 'development');
console.log('📍 Base URL:', process.env.BASE_URL || 'http://dev.br.permutapolicial.com.br:3001');
console.log('═══════════════════════════════════════');

// 2. Dependências
const express = require('express');
const cors = require('cors');
const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const OIDCStrategy = require('passport-azure-ad').OIDCStrategy;
const db = require('./src/config/db');
const apiRoutes = require('./src/api');
const jwt = require('jsonwebtoken');
const session = require('express-session');
const axios = require('axios');

// 3. Configuração do Passport Google OAuth
const callbackURL = `${process.env.BASE_URL || 'http://dev.br.permutapolicial.com.br:3001'}/api/auth/google/callback`;
console.log(`🔗 URL de Callback do Google (DEV): ${callbackURL}`);

passport.use('google', new GoogleStrategy({
    clientID: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    callbackURL: callbackURL,
    proxy: true
},
    async (accessToken, refreshToken, profile, done) => {
        try {
            const email = profile.emails[0].value;
            const googleId = profile.id;
            console.log(`🔐 Login Google (DEV): ${email}`);

            // 1. Busca por Google ID primeiro
            let [users] = await db.execute('SELECT * FROM policiais WHERE google_id = ?', [googleId]);
            if (users.length > 0) {
                console.log(`✅ Usuário encontrado pelo Google ID: ${users[0].email}`);
                return done(null, users[0]);
            }

            // 2. Busca por email para vincular conta existente (Microsoft ou local)
            [users] = await db.execute('SELECT * FROM policiais WHERE email = ?', [email]);
            if (users.length > 0) {
                const user = users[0];
                console.log(`🔗 Vinculando conta Google ao usuário existente: ${email}`);
                if (!user.google_id) {
                    await db.execute('UPDATE policiais SET google_id = ?, status_verificacao = "VERIFICADO" WHERE id = ?', [googleId, user.id]);
                    user.google_id = googleId;
                    user.status_verificacao = 'VERIFICADO';
                }
                return done(null, user);
            }

            // 3. Cria novo usuário
            console.log(`👤 Criando novo usuário Google: ${email}`);
            const [result] = await db.execute(
                `INSERT INTO policiais (nome, email, google_id, auth_provider, status_verificacao, senha_hash, id_funcional, forca_id, qso) 
                 VALUES (?, ?, ?, 'google', 'VERIFICADO', NULL, NULL, NULL, NULL)`,
                [profile.displayName, email, googleId]
            );
            const [newUser] = await db.execute('SELECT * FROM policiais WHERE id = ?', [result.insertId]);
            console.log(`✅ Usuário Google criado: ${newUser[0].email}`);
            return done(null, newUser[0]);
        } catch (error) {
            console.error('💥 Erro OAuth Google:', error);
            return done(error, false);
        }
    }
));

// 4. Configuração do Passport Microsoft OAuth
const microsoftCallbackURL = `${process.env.BASE_URL || 'http://dev.br.permutapolicial.com.br:3001'}/api/auth/microsoft/callback`;
console.log(`🔗 URL de Callback da Microsoft (DEV): ${microsoftCallbackURL}`);

passport.use('microsoft', new OIDCStrategy({
    identityMetadata: 'https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration',
    clientID: process.env.MICROSOFT_CLIENT_ID,
    clientSecret: process.env.MICROSOFT_CLIENT_SECRET,
    redirectUrl: microsoftCallbackURL,
    responseType: 'code',
    responseMode: 'form_post',
    scope: ['openid', 'profile', 'email', 'User.Read'],
    allowHttpForRedirectUrl: process.env.NODE_ENV === 'development', // Permite HTTP em dev
    validateIssuer: false,
    passReqToCallback: false,
    loggingLevel: 'info',
},
    async (iss, sub, profile, accessToken, refreshToken, done) => {
        console.log('═══════════════════════════════════════');
        console.log('🔵 ESTRATÉGIA MICROSOFT EXECUTADA (DEV)');
        console.log('🔑 AccessToken recebido (será usado para o Graph API)');

        let graphProfile;
        try {
            const graphResponse = await axios.get(
                'https://graph.microsoft.com/v1.0/me?$select=displayName,userPrincipalName,businessPhones,officeLocation,city,mail,jobTitle',
                {
                    headers: { 
                        'Authorization': `Bearer ${accessToken}` 
                    }
                }
            );
            graphProfile = graphResponse.data;
            console.log('✅ Perfil do Graph API obtido:', JSON.stringify(graphProfile, null, 2));
        } catch (graphError) {
            console.error('💥 ERRO ao buscar perfil do Graph API:', graphError.response ? graphError.response.data : graphError.message);
            return done(graphError, false);
        }

        try {
            const microsoftId = profile.oid || profile.sub; 
            const email = graphProfile.mail || graphProfile.userPrincipalName;
            const nome = graphProfile.displayName || 'Usuário Microsoft';
            const idFuncional = graphProfile.officeLocation || null; 
            const postoGraduacaoNome = graphProfile.jobTitle || null;

            console.log('📋 Dados extraídos (do Graph API):');
            console.log('   Microsoft ID:', microsoftId);
            console.log('   Email:', email);
            console.log('   Nome:', nome);
            console.log('   ID Funcional (officeLocation):', idFuncional);
            console.log('   Cargo (jobTitle):', postoGraduacaoNome);

            if (!email) {
                console.error('❌ Email não fornecido pelo Graph API');
                return done(new Error('O email não foi fornecido pela Microsoft.'), false);
            }
            if (!microsoftId) {
                console.error('❌ ID não fornecido pelo token');
                return done(new Error('O ID de usuário não foi fornecido pela Microsoft.'), false);
            }

            // 1. Busca por Microsoft ID
            let [users] = await db.execute('SELECT * FROM policiais WHERE microsoft_id = ?', [microsoftId]);
            if (users.length > 0) {
                console.log(`✅ Usuário encontrado pelo Microsoft ID: ${users[0].email}`);
                return done(null, users[0]);
            }

            // 2. Busca por email para vincular conta existente
            [users] = await db.execute('SELECT * FROM policiais WHERE email = ?', [email]);
            if (users.length > 0) {
                console.log(`🔗 Vinculando conta Microsoft ao usuário: ${email}`);
                await db.execute('UPDATE policiais SET microsoft_id = ?, status_verificacao = "VERIFICADO" WHERE id = ?', [microsoftId, users[0].id]);
                const [updatedUser] = await db.execute('SELECT * FROM policiais WHERE id = ?', [users[0].id]);
                console.log(`✅ Conta vinculada: ${updatedUser[0].email}`);
                return done(null, updatedUser[0]);
            }

            // 3. Cria novo usuário
            console.log(`👤 Criando novo usuário Microsoft: ${email}`);
            let forcaId = null;
            let postoId = null;

            if (email.endsWith('@bm.rs.gov.br')) {
                const [forcas] = await db.execute('SELECT id FROM forcas_policiais WHERE sigla = ?', ['BMRS']);
                if (forcas.length > 0) forcaId = forcas[0].id;
            }

            if (postoGraduacaoNome) { 
                const [postos] = await db.execute('SELECT id FROM postos_graduacoes WHERE nome = ?', [postoGraduacaoNome]);
                if (postos.length > 0) postoId = postos[0].id;
            }

            const [result] = await db.execute(
                `INSERT INTO policiais 
                (nome, email, id_funcional, forca_id, posto_graduacao_id, microsoft_id, auth_provider, status_verificacao) 
                VALUES (?, ?, ?, ?, ?, ?, 'microsoft', 'VERIFICADO')`,
                [nome, email, idFuncional, forcaId, postoId, microsoftId]
            );

            const [newUser] = await db.execute('SELECT * FROM policiais WHERE id = ?', [result.insertId]);
            console.log(`✅ Usuário Microsoft criado: ${newUser[0].email}`);
            return done(null, newUser[0]);
        } catch (error) {
            console.error('💥 ERRO na estratégia Microsoft (lógica de BD):', error);
            return done(error, false);
        }
    }));

console.log('✅ Estratégia Microsoft configurada (DEV)');

passport.serializeUser((user, done) => done(null, user.id));
passport.deserializeUser(async (id, done) => {
    try {
        const [users] = await db.execute('SELECT * FROM policiais WHERE id = ?', [id]);
        done(null, users[0]);
    } catch (error) {
        done(error, null);
    }
});

console.log('✅ Passport configurado (DEV)');

// 5. App Express
const app = express();

app.set('trust proxy', 1);

// 6. Middlewares
const corsOptions = {
    origin: function (origin, callback) {
        const allowedOrigins = [
            process.env.FRONTEND_URL || 'http://dev.br.permutapolicial.com.br',
            'http://dev.br.permutapolicial.com.br',
            'https://dev.br.permutapolicial.com.br',
            'http://localhost:3000',
            'https://login.microsoftonline.com',
        ];
        if (!origin) return callback(null, true);
        if (allowedOrigins.indexOf(origin) !== -1) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
};

app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(session({
    secret: process.env.SESSION_SECRET || 'um-segredo-muito-forte-de-fallback-dev',
    resave: false,
    saveUninitialized: true
}));
app.use(passport.initialize());
app.use(passport.session());

console.log('✅ Middlewares configurados (DEV)');

// 7. Rota de Health Check
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'ok',
        uptime: process.uptime(),
        timestamp: new Date().toISOString(),
        environment: 'development'
    });
});

// 8. Rota raiz
app.get('/', (req, res) => {
    res.json({
        message: 'API Permuta Policial - Ambiente de Desenvolvimento',
        status: '✅',
        timestamp: new Date().toISOString(),
        version: '2.0.0-dev'
    });
});

// 9. Rotas da API
console.log('📦 Carregando rotas da API...');
app.use('/api', apiRoutes);
console.log('✅ Rotas da API carregadas');

// 10. 404 Handler
app.use((req, res, next) => {
    res.status(404).json({
        error: 'Rota não encontrada',
        path: req.path,
        method: req.method
    });
});

// 11. Error Handler
const errorHandler = require('./src/core/middlewares/errorHandler');
app.use(errorHandler);

// 12. Inicialização
const PORT = process.env.PORT || 3001;
const HOST = '0.0.0.0'; // Escuta em todas as interfaces para desenvolvimento

async function startServer() {
    try {
        const connection = await db.getConnection();
        console.log('✅ Banco de dados conectado (DEV)');
        connection.release();

        const server = app.listen(PORT, HOST, () => {
            console.log('═══════════════════════════════════════');
            console.log('🚀 Servidor DEV rodando');
            console.log(`📍 Endereço: http://${HOST}:${PORT}`);
            console.log(`📍 Ambiente: DESENVOLVIMENTO`);
            console.log('═══════════════════════════════════════');
        });

        // Graceful shutdown
        const shutdown = (signal) => {
            console.log(`\n📴 ${signal} recebido. Encerrando servidor DEV...`);
            server.close(async () => {
                await db.end();
                process.exit(0);
            });
        };

        process.on('SIGTERM', () => shutdown('SIGTERM'));
        process.on('SIGINT', () => shutdown('SIGINT'));
    } catch (error) {
        console.error('💥 FALHA ao iniciar servidor DEV:', error);
        process.exit(1);
    }
}

startServer();

