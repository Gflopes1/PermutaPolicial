require('dotenv').config();



console.log('═══════════════════════════════════════');

console.log('🚀 Iniciando aplicação...');

console.log('📍 Ambiente:', process.env.NODE_ENV || 'development');

console.log('📍 Base URL:', process.env.BASE_URL);

console.log('═══════════════════════════════════════');



// 2. Dependências

const express = require('express');

const cors = require('cors');

const passport = require('passport');

const GoogleStrategy = require('passport-google-oauth20').Strategy;

const OIDCStrategy = require('passport-azure-ad').OIDCStrategy;

const db = require('./src/config/db');

const apiRoutes = require('./src/api');
const { initializeSocket } = require('./src/config/socket');

const jwt = require('jsonwebtoken');

const session = require('express-session');
const axios = require('axios');



// 3. Configuração do Passport Google OAuth

const callbackURL = `${process.env.BASE_URL || 'https://br.permutapolicial.com.br'}/api/auth/google/callback`;

console.log(`🔗 URL de Callback do Google: ${callbackURL}`);



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

            console.log(`🔐 Login Google: ${email}`);

            // Validação de domínio
            const DOMINIOS_PERMITIDOS = [
                'pm.al.gov.br', 'pm.ap.gov.br', 'pm.am.gov.br', 'pm.ba.gov.br', 'pm.ce.gov.br',
                'pm.df.gov.br', 'pm.es.gov.br', 'pm.go.gov.br', 'pm.ma.gov.br', 'pm.mt.gov.br',
                'pm.ms.gov.br', 'pm.mg.gov.br', 'pm.pa.gov.br', 'pm.pb.gov.br', 'pm.pr.gov.br',
                'pm.pe.gov.br', 'pm.pi.gov.br', 'pm.rj.gov.br', 'pm.rn.gov.br', 'bm.rs.gov.br',
                'pm.ro.gov.br', 'pm.rr.gov.br', 'pm.sc.gov.br', 'policiamilitar.sp.gov.br',
                'pm.se.gov.br', 'pm.to.gov.br',
                'pc.al.gov.br', 'pc.ap.gov.br', 'pc.am.gov.br', 'pc.ba.gov.br', 'pc.ce.gov.br',
                'pc.df.gov.br', 'pc.es.gov.br', 'pc.go.gov.br', 'pc.ma.gov.br', 'pc.mt.gov.br',
                'pc.ms.gov.br', 'pc.mg.gov.br', 'pc.pa.gov.br', 'pc.pb.gov.br', 'pc.pr.gov.br',
                'pc.pe.gov.br', 'pc.pi.gov.br', 'pc.rj.gov.br', 'pc.rn.gov.br', 'pc.rs.gov.br',
                'pc.ro.gov.br', 'pc.rr.gov.br', 'pc.sc.gov.br', 'policiacivil.sp.gov.br',
                'pc.se.gov.br', 'pc.to.gov.br',
                'pf.gov.br', 'prf.gov.br'
            ];
            const dominio = email.toLowerCase().split('@')[1];
            if (!DOMINIOS_PERMITIDOS.includes(dominio)) {
                return done(new Error('Apenas emails com domínios da segurança pública são permitidos. Isso garante a segurança das informações dos policiais.'), false);
            }



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

                

                // Atualiza o google_id e verifica se já não tinha
                if (!user.google_id) {

                    await db.execute(

                        'UPDATE policiais SET google_id = ?, status_verificacao = "VERIFICADO" WHERE id = ?', 

                        [googleId, user.id]

                    );

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

const microsoftCallbackURL = `${process.env.BASE_URL || 'https://br.permutapolicial.com.br'}/api/auth/microsoft/callback`;

console.log(`🔗 URL de Callback da Microsoft: ${microsoftCallbackURL}`);



passport.use('microsoft', new OIDCStrategy({

    identityMetadata: 'https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration',

    clientID: process.env.MICROSOFT_CLIENT_ID,

    clientSecret: process.env.MICROSOFT_CLIENT_SECRET,

    redirectUrl: microsoftCallbackURL,



    // ✅ CONFIGURAÇÕES CORRETAS

    responseType: 'code',

    responseMode: 'form_post', // ← Microsoft retorna via POST

    scope: ['openid', 'profile', 'email', 'User.Read'],



    // ✅ VALIDAÇÕES

    allowHttpForRedirectUrl: false, // Força HTTPS

    validateIssuer: false,

    //issuer: 'https://login.microsoftonline.com/9188040d-6c67-4c5b-b112-36a304b66dad/v2.0', // Comum



    // ✅ IMPORTANTE: Não passa req

    passReqToCallback: false,



    // ✅ LOGS

    loggingLevel: 'info',

},

    async (iss, sub, profile, accessToken, refreshToken, done) => {
        console.log('═══════════════════════════════════════');
        console.log('🔵 ESTRATÉGIA MICROSOFT EXECUTADA');
        console.log('🔑 AccessToken recebido (será usado para o Graph API)');

        // ================================================
        // 1. BUSCAR DADOS DO GRAPH API (A NOVA LÓGICA)
        // ================================================
        let graphProfile;
        try {
            const graphResponse = await axios.get(
                // A TUA URL DO GRAPH API:
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

        // ================================================
        // 2. USAR OS DADOS DO GRAPH API
        // ================================================
        try {
            // ID do token original, dados do Graph API
            const microsoftId = profile.oid || profile.sub; 
            const email = graphProfile.mail || graphProfile.userPrincipalName;
            const nome = graphProfile.displayName || 'Usuário Microsoft';

            // OS NOVOS DADOS QUE VOCÊ QUERIA:
            const idFuncional = graphProfile.officeLocation || null; 
            const postoGraduacaoNome = graphProfile.jobTitle || null;

            console.log('📋 Dados extraídos (do Graph API):');
            console.log('   Microsoft ID:', microsoftId);
            console.log('   Email:', email);
            console.log('   Nome:', nome);
            console.log('   ID Funcional (officeLocation):', idFuncional);
            console.log('   Cargo (jobTitle):', postoGraduacaoNome);

            // O resto do teu código (que já está correto no teu ficheiro) continua aqui...
            // (if (!email), if (!microsoftId), busca por ID, busca por email, cria novo usuário)

            // ✅ VALIDAÇÃO
            if (!email) {
                console.error('❌ Email não fornecido pelo Graph API');
                return done(new Error('O email não foi fornecido pela Microsoft.'), false);
            }
            if (!microsoftId) {
                console.error('❌ ID não fornecido pelo token');
                return done(new Error('O ID de usuário não foi fornecido pela Microsoft.'), false);
            }

            // Validação de domínio
            const DOMINIOS_PERMITIDOS = [
                'pm.al.gov.br', 'pm.ap.gov.br', 'pm.am.gov.br', 'pm.ba.gov.br', 'pm.ce.gov.br',
                'pm.df.gov.br', 'pm.es.gov.br', 'pm.go.gov.br', 'pm.ma.gov.br', 'pm.mt.gov.br',
                'pm.ms.gov.br', 'pm.mg.gov.br', 'pm.pa.gov.br', 'pm.pb.gov.br', 'pm.pr.gov.br',
                'pm.pe.gov.br', 'pm.pi.gov.br', 'pm.rj.gov.br', 'pm.rn.gov.br', 'bm.rs.gov.br',
                'pm.ro.gov.br', 'pm.rr.gov.br', 'pm.sc.gov.br', 'policiamilitar.sp.gov.br',
                'pm.se.gov.br', 'pm.to.gov.br',
                'pc.al.gov.br', 'pc.ap.gov.br', 'pc.am.gov.br', 'pc.ba.gov.br', 'pc.ce.gov.br',
                'pc.df.gov.br', 'pc.es.gov.br', 'pc.go.gov.br', 'pc.ma.gov.br', 'pc.mt.gov.br',
                'pc.ms.gov.br', 'pc.mg.gov.br', 'pc.pa.gov.br', 'pc.pb.gov.br', 'pc.pr.gov.br',
                'pc.pe.gov.br', 'pc.pi.gov.br', 'pc.rj.gov.br', 'pc.rn.gov.br', 'pc.rs.gov.br',
                'pc.ro.gov.br', 'pc.rr.gov.br', 'pc.sc.gov.br', 'policiacivil.sp.gov.br',
                'pc.se.gov.br', 'pc.to.gov.br',
                'pf.gov.br', 'prf.gov.br'
            ];
            const dominio = email.toLowerCase().split('@')[1];
            if (!DOMINIOS_PERMITIDOS.includes(dominio)) {
                return done(new Error('Apenas emails com domínios da segurança pública são permitidos. Isso garante a segurança das informações dos policiais.'), false);
            }

            // 1. Busca por Microsoft ID
            let [users] = await db.execute(
                'SELECT * FROM policiais WHERE microsoft_id = ?',
                [microsoftId]
            );

            if (users.length > 0) {
                console.log(`✅ Usuário encontrado pelo Microsoft ID: ${users[0].email}`);
                return done(null, users[0]);
            }

            // 2. Busca por email para vincular conta existente
            [users] = await db.execute(
                'SELECT * FROM policiais WHERE email = ?',
                [email]
            );

            if (users.length > 0) {
                console.log(`🔗 Vinculando conta Microsoft ao usuário: ${email}`);
                await db.execute(
                    'UPDATE policiais SET microsoft_id = ?, status_verificacao = "VERIFICADO" WHERE id = ?',
                    [microsoftId, users[0].id]
                );

                const [updatedUser] = await db.execute(
                    'SELECT * FROM policiais WHERE id = ?',
                    [users[0].id]
                );

                console.log(`✅ Conta vinculada: ${updatedUser[0].email}`);
                return done(null, updatedUser[0]);
            }

            // 3. Cria novo usuário (agora com os dados do Graph)
            console.log(`👤 Criando novo usuário Microsoft: ${email}`);

            let forcaId = null;
            let postoId = null;

            if (email.endsWith('@bm.rs.gov.br')) {
                const [forcas] = await db.execute('SELECT id FROM forcas_policiais WHERE sigla = ?', ['BMRS']);
                if (forcas.length > 0) forcaId = forcas[0].id;
            }

            // A tua lógica que busca o "Soldado" já vai funcionar
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

            const [newUser] = await db.execute(
                'SELECT * FROM policiais WHERE id = ?',
                [result.insertId]
            );

            console.log(`✅ Usuário Microsoft criado: ${newUser[0].email}`);
            return done(null, newUser[0]);

        } catch (error) {
            console.error('💥 ERRO na estratégia Microsoft (lógica de BD):', error);
            return done(error, false);
        }
    }));



console.log('✅ Estratégia Microsoft configurada');



passport.serializeUser((user, done) => done(null, user.id));

passport.deserializeUser(async (id, done) => {

    try {

        const [users] = await db.execute('SELECT * FROM policiais WHERE id = ?', [id]);

        done(null, users[0]);

    } catch (error) {

        done(error, null);

    }

});



console.log('✅ Passport configurado');



// 5. App Express

const app = express();



app.set('trust proxy', 1);



// 6. Middlewares

const corsOptions = {

    origin: function (origin, callback) {

        const allowedOrigins = [

            process.env.FRONTEND_URL || 'http://localhost:3000',

            'https://br.permutapolicial.com.br',

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

    secret: process.env.SESSION_SECRET || 'um-segredo-muito-forte-de-fallback',

    resave: false,

    saveUninitialized: true

}));

app.use(passport.initialize());

app.use(passport.session());



console.log('✅ Middlewares configurados');



// 7. Rota de Health Check

app.get('/health', (req, res) => {

    res.status(200).json({

        status: 'ok',

        uptime: process.uptime(),

        timestamp: new Date().toISOString(),

        environment: process.env.NODE_ENV || 'development'

    });

});



// 8. Rota raiz

app.get('/', (req, res) => {

    res.json({

        message: 'API Permuta Policial - Online',

        status: '✅',

        timestamp: new Date().toISOString(),

        version: '2.0.0'

    });

});



// 9. Servir arquivos estáticos (uploads)
const path = require('path');
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// 10. Rotas da API

console.log('📦 Carregando rotas da API...');

app.use('/api', apiRoutes);

console.log('✅ Rotas da API carregadas');



// 11. 404 Handler

app.use((req, res, next) => {

    res.status(404).json({

        error: 'Rota não encontrada',

        path: req.path,

        method: req.method

    });

});



// 12. Error Handler

app.use((err, req, res, next) => {

    console.error('💥 ERRO:', err.message);

    res.status(err.statusCode || 500).json({

        error: err.message || 'Erro interno do servidor',

        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })

    });

});



// ===== INICIALIZAÇÃO PARA PASSENGER =====



// Detecta se está rodando no Passenger

const isPassenger = process.env.PASSENGER_INSTANCE_REGISTRY_DIR !== undefined;



if (isPassenger) {

    console.log('═══════════════════════════════════════');

    console.log('🚀 MODO PASSENGER DETECTADO');

    console.log('📍 O Passenger gerenciará o servidor');

    console.log('═══════════════════════════════════════');



    // Testa conexão com banco de forma assíncrona

    db.getConnection()

        .then(connection => {

            console.log('✅ Banco de dados conectado');

            connection.release();

        })

        .catch(error => {

            console.error('💥 ERRO ao conectar ao banco:', error.message);

        });



    // Exporta a app para o Passenger

    module.exports = app;



} else {

    // Modo standalone (PM2, nodemon, etc)

    const PORT = process.env.PORT || 3000;

    const HOST = '127.0.0.1';



    async function startServer() {

        try {

            const connection = await db.getConnection();

            console.log('✅ Banco de dados conectado');

            connection.release();



            const server = app.listen(PORT, HOST, () => {

                console.log('═══════════════════════════════════════');

                console.log('🚀 Servidor rodando');

                console.log(`📍 Endereço: ${HOST}:${PORT}`);

                console.log('═══════════════════════════════════════');

            });

            // Inicializa Socket.IO para chat em tempo real
            initializeSocket(server);
            console.log('✅ Socket.IO inicializado');

            // Inicializa serviço de limpeza automática
            const cleanupService = require('./src/core/services/cleanup_service');
            
            // Executa limpeza imediatamente ao iniciar (opcional)
            // cleanupService.runCleanup();
            
            // Executa limpeza a cada 24 horas
            const cleanupInterval = 24 * 60 * 60 * 1000; // 24 horas em milissegundos
            setInterval(async () => {
                try {
                    await cleanupService.runCleanup();
                } catch (error) {
                    console.error('Erro na limpeza automática:', error);
                }
            }, cleanupInterval);
            
            console.log('✅ Serviço de limpeza automática inicializado (executa a cada 24h)');



            // Graceful shutdown

            const shutdown = (signal) => {

                console.log(`\n📴 ${signal} recebido. Encerrando...`);

                server.close(async () => {

                    await db.end();

                    process.exit(0);

                });

            };



            process.on('SIGTERM', () => shutdown('SIGTERM'));

            process.on('SIGINT', () => shutdown('SIGINT'));



        } catch (error) {

            console.error('💥 FALHA ao iniciar:', error);

            process.exit(1);

        }

    }



    startServer();

}



// --- FIM DO ARQUIVO: server.js ---