// --- INÍCIO DO ARQUIVO: server.js ---

// 1. Configuração de ambiente
require('dotenv').config();

// Tratamento de exceções não capturadas
process.on('uncaughtException', (error) => {
    console.error('💥 EXCEÇÃO NÃO CAPTURADA:', error);
    gracefulShutdown('uncaughtException');
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('💥 PROMISE REJECTION NÃO TRATADA:', reason);
    console.error('Promise:', promise);
    gracefulShutdown('unhandledRejection');
});

// --- INÍCIO: Redirecionamento de Log ---
// Força o console.log() a escrever em stderr,
console.log = function (d) {
    process.stderr.write(d + '\n');
};
console.info = console.log;
console.warn = console.error;
// --- FIM: Redirecionamento de Log ---

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

// ===== CONFIGURAÇÃO ESPECÍFICA PARA LITESPEED =====
console.log('🚀 Iniciando servidor...');
console.log('📍 Ambiente:', process.env.NODE_ENV || 'development');
console.log('📍 Porta:', process.env.PORT || 3000);
console.log('📍 Base URL:', process.env.BASE_URL);


// 3. Configuração do Passport Google OAuth
const callbackURL = `${process.env.BASE_URL || 'https://br.permutapolicial.com.br'}/api/auth/google/callback`;
console.log(`🔗 URL de Callback do Google configurada para: ${callbackURL}`);

passport.use('google', new GoogleStrategy({
    clientID: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    callbackURL: callbackURL,
    // ✅ IMPORTANTE para LiteSpeed: confiar no proxy
    proxy: true
},
    async (accessToken, refreshToken, profile, done) => {
        try {
            const email = profile.emails[0].value;
            const googleId = profile.id;
            console.log(`🔐 Tentativa de login com Google para: ${email}`);

            // Verifica se o usuário já existe pelo email
            let [users] = await db.execute(
                'SELECT * FROM policiais WHERE email = ?',
                [email]
            );

            if (users.length > 0) {
                const user = users[0];
                // Se o usuário existe mas não tem google_id, vincule a conta
                if (!user.google_id) {
                    console.log(`🔗 Vinculando conta Google ao usuário existente: ${email}`);
                    await db.execute(
                        'UPDATE policiais SET google_id = ?, status_verificacao = "VERIFICADO" WHERE id = ?',
                        [googleId, user.id]
                    );
                    // Atualiza o objeto user com o google_id
                    user.google_id = googleId;
                    user.status_verificacao = 'VERIFICADO';
                }
                console.log(`✅ Usuário encontrado: ${user.email}`);
                return done(null, user);
            }

            // Se não existe, cria um novo usuário
            console.log(`👤 Criando novo usuário para: ${email}`);
            const [result] = await db.execute(
                `INSERT INTO policiais 
                    (nome, email, google_id, auth_provider, status_verificacao, senha_hash, id_funcional, forca_id, qso) 
                 VALUES 
                    (?, ?, ?, 'google', 'VERIFICADO', NULL, NULL, NULL, NULL)`,
                [profile.displayName, email, googleId]
            );

            const [newUser] = await db.execute('SELECT * FROM policiais WHERE id = ?', [result.insertId]);
            console.log(`✅ Usuário criado com sucesso: ${newUser[0].email}`);
            return done(null, newUser[0]);

        } catch (error) {
            console.error('💥 Erro durante a estratégia OAuth do Google:', error);
            return done(error, false);
        }
    }
));

const microsoftCallbackURL = 'https://br.permutapolicial.com.br/api/auth/microsoft/callback';
console.log(`🔗 URL de Callback da Microsoft configurada para: ${microsoftCallbackURL}`);

passport.use('microsoft', new OIDCStrategy({
    identityMetadata: 'https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration',
    authorizationURL: 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
    tokenURL: 'https://login.microsoftonline.com/common/oauth2/v2.0/token',
    issuer: 'https://login.microsoftonline.com/common/v2.0',
    validateIssuer: true,
    clientID: process.env.MICROSOFT_CLIENT_ID,
    clientSecret: process.env.MICROSOFT_CLIENT_SECRET,
    redirectUrl: microsoftCallbackURL,
    responseType: 'code',
    responseMode: 'form_post',
    scope: ['profile', 'email', 'openid', 'User.Read'],
    passReqToCallback: false,

},
    async (iss, sub, profile, done) => {
        try {

            console.log('--- DEBUG: PERFIL RECEBIDO DA MICROSOFT ---');
            console.log(JSON.stringify(profile, null, 2));
            console.log('-----------------------------------------');

            const microsoftId = profile.oid; // O 'oid' (Object ID) é o identificador único e imutável
            const email = profile.upn || profile._json.mail;
            const nome = profile.displayName;
            const idFuncional = profile._json.officeLocation;
            const postoGraduacaoNome = profile._json.jobTitle;

            if (!email) {
                console.error('💥 Erro Microsoft OAuth: O email não foi retornado.');
                return done(new Error('O email não foi fornecido pela Microsoft.'), false);
            }
            if (!microsoftId) {
                console.error('💥 Erro Microsoft OAuth: O OID (microsoftId) não foi retornado.');
                return done(new Error('O ID de usuário (OID) não foi fornecido pela Microsoft.'), false);
            }

            console.log(`🔐 Tentativa de login com Microsoft para: ${email} (ID: ${microsoftId})`);

            // 1. Tenta encontrar o usuário pelo Microsoft ID
            let [users] = await db.execute('SELECT * FROM policiais WHERE microsoft_id = ?', [microsoftId]);
            if (users.length > 0) {
                console.log(`✅ Usuário Microsoft encontrado pelo ID: ${users[0].email}`);
                return done(null, users[0]);
            }

            // 2. Se não encontrou, tenta encontrar pelo e-mail para vincular a conta
            [users] = await db.execute('SELECT * FROM policiais WHERE email = ?', [email]);
            if (users.length > 0) {
                console.log(`🔗 Vinculando conta Microsoft ao usuário existente: ${email}`);
                await db.execute('UPDATE policiais SET microsoft_id = ? WHERE id = ?', [microsoftId, users[0].id]);
                // Retorna o usuário encontrado e agora vinculado
                const [updatedUser] = await db.execute('SELECT * FROM policiais WHERE id = ?', [users[0].id]);
                return done(null, updatedUser[0]);
            }

            // 3. Se não encontrou de nenhuma forma, cria um novo usuário
            console.log(`👤 Criando novo usuário Microsoft para: ${email}`);

            // Lógica para pré-buscar forca_id e posto_graduacao_id (como antes)
            let forcaId = null;
            let postoId = null;
            if (email.endsWith('@bm.rs.gov.br')) {
                const [forcas] = await db.execute('SELECT id FROM forcas_policiais WHERE sigla = ?', ['PMRS']);
                if (forcas.length > 0) forcaId = forcas[0].id;
            }
            if (postoGraduacaoNome) {
                const [postos] = await db.execute('SELECT id FROM postos_graduacoes WHERE nome = ?', [postoGraduacaoNome]);
                if (postos.length > 0) postoId = postos[0].id;
            }

            const [result] = await db.execute(
                `INSERT INTO policiais 
                (nome, email, id_funcional, forca_id, posto_graduacao_id, microsoft_id, auth_provider, status_verificacao) 
             VALUES 
                (?, ?, ?, ?, ?, ?, 'microsoft', 'VERIFICADO')`,
                [nome, email, idFuncional, forcaId, postoId, microsoftId]
            );

            const [newUser] = await db.execute('SELECT * FROM policiais WHERE id = ?', [result.insertId]);
            console.log(`✅ Usuário Microsoft criado com sucesso: ${newUser[0].email}`);
            return done(null, newUser[0]);

        } catch (error) {
            console.error('💥 Erro durante a estratégia OAuth da Microsoft:', error);
            return done(error, false);
        }
    }));
console.log('✅ Estratégia "microsoft" do Passport registrada.');

// Serialização do usuário (necessário mesmo com session: false)
passport.serializeUser((user, done) => {
    done(null, user.id);
});

passport.deserializeUser(async (id, done) => {
    try {
        const [users] = await db.execute('SELECT * FROM policiais WHERE id = ?', [id]);
        done(null, users[0]);
    } catch (error) {
        done(error, null);
    }
});

console.log('✅ Estratégia "google" do Passport registrada.');

// 4. App Express
const app = express();

// ✅ IMPORTANTE: Configuração para LiteSpeed proxy
app.set('trust proxy', 1);
app.set('trust proxy', 'loopback');

// 5. Middlewares
const corsOptions = {
    origin: function (origin, callback) {
        const allowedOrigins = [
            process.env.FRONTEND_URL || 'http://localhost:3000',
            'https://br.permutapolicial.com.br',
            'http://localhost:3000',
            'https://login.microsoftonline.com',
        ];

        // Permite requisições sem origin (mobile apps, Postman, etc)
        if (!origin) return callback(null, true);

        if (allowedOrigins.indexOf(origin) !== -1) {
            callback(null, true);
        } else {
            console.log('❌ Origem bloqueada pelo CORS:', origin);
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
    secret: process.env.SESSION_SECRET || 'um-segredo-muito-forte-de-fallback',
    resave: false,
    saveUninitialized: true
}));
app.use(passport.initialize());
app.use(passport.session());


console.log('✅ Middlewares configurados.');

// ===== MIDDLEWARE DE LOG PARA DEBUG =====
app.use((req, res, next) => {
    console.log('📥 Requisição recebida:', {
        timestamp: new Date().toISOString(),
        method: req.method,
        url: req.url,
        path: req.path,
        query: req.query,
        headers: {
            host: req.headers.host,
            origin: req.headers.origin,
            referer: req.headers.referer,
            'user-agent': req.headers['user-agent']?.substring(0, 50)
        }
    });
    next();
});

// 6. Rota de Health Check (para LiteSpeed)
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'ok',
        uptime: process.uptime(),
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development'
    });
});

// 7. Rota raiz de verificação
app.get('/', (req, res) => {
    res.json({
        message: 'API Permuta Policial - Online',
        status: '✅',
        timestamp: new Date().toISOString(),
        version: '2.0.0'
    });
});

// 8. Rotas da API
console.log('📦 Carregando rotas da API...');
app.use('/api', apiRoutes);
console.log('✅ Rotas da API montadas no prefixo /api.');

// 9. Middleware para rotas não encontradas
const ApiError = require('./src/core/utils/ApiError');
app.use((req, res, next) => {
    console.log('❌ Rota não encontrada:', req.path);
    next(ApiError.notFound(`Rota não encontrada: ${req.method} ${req.path}`));
});

// 10. Error Handler Genérico (usando o middleware centralizado)
const errorHandler = require('./src/core/middlewares/errorHandler');
app.use(errorHandler);

const PORT = process.env.PORT || 3000;
const HOST = '127.0.0.1';

// 11. Variável para armazenar a instância do servidor
let server;

// Função para iniciar o servidor
async function startServer() {
    try {
        // Testa a conexão com o banco de dados
        const connection = await db.getConnection();
        console.log('✅ Banco de dados conectado com sucesso.');
        connection.release();

        // Inicia o servidor
        server = app.listen(PORT, HOST, () => {
            console.log('═══════════════════════════════════════');
            console.log('🚀 Servidor pronto e escutando');
            console.log(`📍 Endereço: ${HOST}:${PORT}`);
            console.log(`🌐 URL Base: ${process.env.BASE_URL}`);
            console.log(`🔐 Google OAuth: ${process.env.GOOGLE_CLIENT_ID ? '✅ Configurado' : '❌ NÃO configurado'}`);
            console.log(`🔗 Callback URL: ${callbackURL}`);
            console.log(`📧 Email Service: ${process.env.MAIL_HOST ? '✅ Configurado' : '❌ NÃO configurado'}`);
            console.log(`🗄️  Database: ${process.env.DB_NAME ? '✅ Configurado' : '❌ NÃO configurado'}`);
            console.log('═══════════════════════════════════════');
        });

        // Tratamento de erros do servidor
        server.on('error', (error) => {
            console.error('💥 ERRO NO SERVIDOR:', error);
            if (error.code === 'EADDRINUSE') {
                console.error(`❌ Porta ${PORT} já está em uso`);
                console.log('💡 Tente: killall -9 node ou pm2 stop all');
                process.exit(1);
            } else if (error.code === 'EACCES') {
                console.error(`❌ Sem permissão para usar a porta ${PORT}`);
                process.exit(1);
            } else {
                console.error('❌ Erro desconhecido:', error);
                process.exit(1);
            }
        });

        // Tratamento de conexões
        server.on('connection', (socket) => {
            console.log('🔌 Nova conexão estabelecida');
        });

    } catch (error) {
        console.error('💥 FALHA CRÍTICA: Não foi possível iniciar o servidor.');
        console.error('Erro:', error.message);
        console.error('Stack:', error.stack);
        process.exit(1);
    }
}

// Função para encerrar graciosamente
async function gracefulShutdown(signal) {
    console.log(`\n📴 ${signal} recebido. Encerrando graciosamente...`);
    
    if (server) {
        server.close(async () => {
            console.log('✅ Servidor HTTP encerrado.');
            
            try {
                await db.end();
                console.log('✅ Conexões com o banco de dados encerradas.');
            } catch (error) {
                console.error('❌ Erro ao encerrar conexões do banco:', error);
            }
            
            console.log('👋 Processo finalizado.');
            process.exit(0);
        });

        // Força o encerramento após 10 segundos
        setTimeout(() => {
            console.error('⏱️  Tempo limite excedido. Forçando encerramento...');
            process.exit(1);
        }, 10000);
    } else {
        process.exit(0);
    }
}

// Tratamento de sinais de encerramento
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Tratamento de exceções não capturadas
process.on('uncaughtException', (error) => {
    console.error('💥 EXCEÇÃO NÃO CAPTURADA:', error);
    gracefulShutdown('uncaughtException');
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('💥 PROMISE REJECTION NÃO TRATADA:', reason);
    console.error('Promise:', promise);
    gracefulShutdown('unhandledRejection');
});

// ✅ CORREÇÃO: Exporta a app para o LiteSpeed/Passenger E inicia o servidor
// Se estiver sendo executado diretamente (PM2, console), inicia o servidor
// Se estiver sendo importado pelo Passenger, apenas exporta a app
if (require.main === module) {
    // Executado diretamente via node, nodemon ou PM2
    startServer();
} else {
    // Importado pelo Passenger/LiteSpeed
    // O Passenger gerencia o servidor automaticamente
    module.exports = app;
}

// --- FIM DO ARQUIVO: server.js ---